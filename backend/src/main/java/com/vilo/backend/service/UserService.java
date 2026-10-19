package com.vilo.backend.service;

import com.vilo.backend.dto.UpdateProfileRequest;
import com.vilo.backend.dto.UserResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public UserResponse getProfile(User currentUser) {
        User user = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return UserResponse.fromEntity(user);
    }

    @Transactional(readOnly = true)
    public UserResponse getUserById(Long id) {
        return getUserById(id, null);
    }

    @Transactional(readOnly = true)
    public UserResponse getUserById(Long id, User currentUser) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
        return buildUserResponse(user, currentUser);
    }

    @Transactional(readOnly = true)
    public UserResponse getUserByIdOrUsername(String identifier, User currentUser) {
        User user = null;
        try {
            Long id = Long.parseLong(identifier);
            user = userRepository.findById(id).orElse(null);
        } catch (NumberFormatException ignored) {}

        if (user == null) {
            String clean = identifier.startsWith("@") ? identifier.substring(1) : identifier;
            user = userRepository.findByUsername(clean).orElse(null);
        }

        if (user == null) {
            throw new ResourceNotFoundException("User not found with identifier: " + identifier);
        }

        return buildUserResponse(user, currentUser);
    }

    public Long resolveUserId(String identifier) {
        try {
            return Long.parseLong(identifier);
        } catch (NumberFormatException ignored) {}

        String clean = identifier.startsWith("@") ? identifier.substring(1) : identifier;
        return userRepository.findByUsername(clean)
                .map(User::getId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with identifier: " + identifier));
    }

    private UserResponse buildUserResponse(User user, User currentUser) {
        UserResponse response = UserResponse.fromEntity(user);
        if (currentUser != null && !currentUser.getId().equals(user.getId())) {
            boolean following = user.getFollowers().stream()
                    .anyMatch(f -> f.getId().equals(currentUser.getId()));
            boolean followsYou = user.getFollowing().stream()
                    .anyMatch(f -> f.getId().equals(currentUser.getId()));
            response.setIsFollowing(following);
            response.setFollowsYou(followsYou);
        }
        return response;
    }

    @Transactional
    public UserResponse updateProfile(User currentUser, UpdateProfileRequest request) {
        User user = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (request.getDisplayName() != null && !request.getDisplayName().isBlank()) {
            user.setDisplayName(request.getDisplayName().trim());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio().trim());
        }
        if (request.getAvatarUrl() != null && !request.getAvatarUrl().isBlank()) {
            user.setAvatarUrl(request.getAvatarUrl().trim());
        }

        User updatedUser = userRepository.save(user);
        return UserResponse.fromEntity(updatedUser);
    }

    @Transactional
    public boolean toggleFollow(User currentUser, Long targetUserId) {
        if (currentUser.getId().equals(targetUserId)) {
            throw new BadRequestException("You cannot follow yourself");
        }

        User user = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Target user not found with id: " + targetUserId));

        boolean isFollowing = targetUser.getFollowers().stream()
                .anyMatch(f -> f.getId().equals(user.getId()));

        if (isFollowing) {
            targetUser.getFollowers().removeIf(f -> f.getId().equals(user.getId()));
            user.getFollowing().removeIf(f -> f.getId().equals(targetUser.getId()));
            userRepository.save(targetUser);
            userRepository.save(user);
            return false; // unfollowed
        } else {
            targetUser.getFollowers().add(user);
            user.getFollowing().add(targetUser);
            userRepository.save(targetUser);
            userRepository.save(user);
            return true; // followed
        }
    }

    @Transactional
    public void unfollow(User currentUser, Long targetUserId) {
        if (currentUser.getId().equals(targetUserId)) {
            throw new BadRequestException("You cannot unfollow yourself");
        }

        User user = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Target user not found with id: " + targetUserId));

        targetUser.getFollowers().removeIf(f -> f.getId().equals(user.getId()));
        user.getFollowing().removeIf(f -> f.getId().equals(targetUser.getId()));
        userRepository.save(targetUser);
        userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public List<UserResponse> getFollowers(Long userId, User currentUser) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        final boolean isViewingSelf = currentUser != null && currentUser.getId().equals(userId);
        java.util.Set<Long> myFollowingIds = java.util.Collections.emptySet();
        java.util.Set<Long> myFollowerIds = java.util.Collections.emptySet();

        if (currentUser != null) {
            User me = isViewingSelf ? user : userRepository.findById(currentUser.getId()).orElse(null);
            if (me != null) {
                myFollowingIds = me.getFollowing().stream().map(User::getId).collect(Collectors.toSet());
                if (!isViewingSelf) {
                    myFollowerIds = me.getFollowers().stream().map(User::getId).collect(Collectors.toSet());
                }
            }
        }

        final java.util.Set<Long> finalFollowingIds = myFollowingIds;
        final java.util.Set<Long> finalFollowerIds = myFollowerIds;

        return user.getFollowers().stream()
                .map(follower -> {
                    UserResponse resp = UserResponse.fromEntitySummary(follower);
                    if (currentUser != null && !currentUser.getId().equals(follower.getId())) {
                        resp.setIsFollowing(finalFollowingIds.contains(follower.getId()));
                        resp.setFollowsYou(isViewingSelf ? true : finalFollowerIds.contains(follower.getId()));
                    }
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<UserResponse> getFollowing(Long userId, User currentUser) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        final boolean isViewingSelf = currentUser != null && currentUser.getId().equals(userId);
        java.util.Set<Long> myFollowingIds = java.util.Collections.emptySet();
        java.util.Set<Long> myFollowerIds = java.util.Collections.emptySet();

        if (currentUser != null) {
            User me = isViewingSelf ? user : userRepository.findById(currentUser.getId()).orElse(null);
            if (me != null) {
                myFollowerIds = me.getFollowers().stream().map(User::getId).collect(Collectors.toSet());
                if (!isViewingSelf) {
                    myFollowingIds = me.getFollowing().stream().map(User::getId).collect(Collectors.toSet());
                }
            }
        }

        final java.util.Set<Long> finalFollowingIds = myFollowingIds;
        final java.util.Set<Long> finalFollowerIds = myFollowerIds;

        return user.getFollowing().stream()
                .map(target -> {
                    UserResponse resp = UserResponse.fromEntitySummary(target);
                    if (currentUser != null && !currentUser.getId().equals(target.getId())) {
                        resp.setIsFollowing(isViewingSelf ? true : finalFollowingIds.contains(target.getId()));
                        resp.setFollowsYou(finalFollowerIds.contains(target.getId()));
                    }
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<UserResponse> getSuggestedUsers(User currentUser) {
        Long currentUserId = currentUser != null ? currentUser.getId() : -1L;
        List<User> allUsers = userRepository.findAll();

        java.util.Set<Long> myFollowingIds = java.util.Collections.emptySet();
        java.util.Set<Long> myFollowerIds = java.util.Collections.emptySet();

        if (currentUser != null) {
            User me = userRepository.findById(currentUser.getId()).orElse(null);
            if (me != null) {
                myFollowingIds = me.getFollowing().stream().map(User::getId).collect(Collectors.toSet());
                myFollowerIds = me.getFollowers().stream().map(User::getId).collect(Collectors.toSet());
            }
        }

        final java.util.Set<Long> finalFollowingIds = myFollowingIds;
        final java.util.Set<Long> finalFollowerIds = myFollowerIds;

        return allUsers.stream()
                .filter(u -> !u.getId().equals(currentUserId))
                .map(target -> {
                    UserResponse resp = UserResponse.fromEntitySummary(target);
                    if (currentUser != null) {
                        resp.setIsFollowing(finalFollowingIds.contains(target.getId()));
                        resp.setFollowsYou(finalFollowerIds.contains(target.getId()));
                    }
                    return resp;
                })
                .collect(Collectors.toList());
    }
}
