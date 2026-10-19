package com.vilo.backend.service;

import com.vilo.backend.dto.CreateStoryRequest;
import com.vilo.backend.dto.StoryResponse;
import com.vilo.backend.dto.StoryViewerResponse;
import com.vilo.backend.entity.NotificationType;
import com.vilo.backend.entity.StoryView;
import com.vilo.backend.entity.ThoughtStory;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.StoryViewRepository;
import com.vilo.backend.repository.ThoughtStoryRepository;
import com.vilo.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;

@Service
public class StoryService {

    private static final Logger log = LoggerFactory.getLogger(StoryService.class);

    private final ThoughtStoryRepository storyRepository;
    private final StoryViewRepository storyViewRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public StoryService(
            ThoughtStoryRepository storyRepository,
            StoryViewRepository storyViewRepository,
            UserRepository userRepository,
            NotificationService notificationService
    ) {
        this.storyRepository = storyRepository;
        this.storyViewRepository = storyViewRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<StoryResponse> getActiveStories(User currentUser) {
        Instant now = Instant.now();
        User managedUser = userRepository.findById(currentUser.getId()).orElse(currentUser);
        Set<User> following = managedUser.getFollowing();

        List<ThoughtStory> rawStories;
        if (following != null && !following.isEmpty()) {
            rawStories = storyRepository.findActiveForUsersAndSelf(following, managedUser, now);
        } else {
            rawStories = storyRepository.findAllActive(now);
        }

        // Privacy filtering:
        // PUBLIC: everyone can view
        // FOLLOWERS: currentUser must follow the author (or is author)
        // FRIENDS: currentUser and author are mutual friends (or is author)
        java.util.Set<Long> followingIds = managedUser.getFollowing() != null
                ? managedUser.getFollowing().stream().map(User::getId).collect(java.util.stream.Collectors.toSet())
                : java.util.Collections.emptySet();
        java.util.Set<Long> followerIds = managedUser.getFollowers() != null
                ? managedUser.getFollowers().stream().map(User::getId).collect(java.util.stream.Collectors.toSet())
                : java.util.Collections.emptySet();

        return rawStories.stream()
                .filter(s -> {
                    if (s.getUser().getId().equals(managedUser.getId())) {
                        return true; // Owner can always view own stories
                    }
                    String priv = s.getPrivacy() != null ? s.getPrivacy().toUpperCase() : "PUBLIC";
                    if ("FRIENDS".equals(priv)) {
                        // Mutual friends: both follow each other
                        return followingIds.contains(s.getUser().getId()) && followerIds.contains(s.getUser().getId());
                    } else if ("FOLLOWERS".equals(priv)) {
                        // Current user must follow the author
                        return followingIds.contains(s.getUser().getId());
                    }
                    return true; // PUBLIC
                })
                .map(s -> mapToResponse(s, managedUser))
                .toList();
    }

    @Transactional
    public StoryResponse createStory(User currentUser, CreateStoryRequest request) {
        int durationHours = request.getExpiresInHours() != null && request.getExpiresInHours() > 0
                ? request.getExpiresInHours()
                : 24;

        Instant expiresAt = Instant.now().plus(Duration.ofHours(durationHours));

        String mediaType = request.getMediaType() != null && !request.getMediaType().isBlank()
                ? request.getMediaType().toUpperCase()
                : (request.getMediaUrl() != null && !request.getMediaUrl().isBlank() ? "IMAGE" : "TEXT");

        String privacy = request.getPrivacy() != null && !request.getPrivacy().isBlank()
                ? request.getPrivacy().toUpperCase()
                : "PUBLIC";

        String message = request.getMessage() != null ? request.getMessage().trim() : "";

        ThoughtStory story = ThoughtStory.builder()
                .user(currentUser)
                .message(message)
                .mediaUrl(request.getMediaUrl())
                .mediaType(mediaType)
                .privacy(privacy)
                .musicTrackId(request.getMusicTrackId())
                .musicTitle(request.getMusicTitle())
                .musicArtist(request.getMusicArtist())
                .musicAlbumArt(request.getMusicAlbumArt())
                .musicPreviewUrl(request.getMusicPreviewUrl())
                .musicDuration(request.getMusicDuration())
                .backgroundGradient(request.getBackgroundGradient())
                .viewCount(0)
                .expiresAt(expiresAt)
                .build();

        ThoughtStory saved = storyRepository.save(story);
        return mapToResponse(saved, currentUser);
    }

    @Transactional
    public StoryResponse recordView(User currentUser, Long storyId) {
        ThoughtStory story = storyRepository.findById(storyId)
                .orElseThrow(() -> new ResourceNotFoundException("Story not found with id: " + storyId));

        if (story.getExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("This story has already expired");
        }

        boolean isOwner = story.getUser().getId().equals(currentUser.getId());
        if (!isOwner) {
            boolean alreadyViewed = storyViewRepository.existsByStoryAndViewer(story, currentUser);
            if (!alreadyViewed) {
                StoryView view = StoryView.builder()
                        .story(story)
                        .viewer(currentUser)
                        .build();
                storyViewRepository.save(view);

                story.setViewCount(story.getViewCount() + 1);
                storyRepository.save(story);

                // Notify owner if viewed by another user
                try {
                    notificationService.sendNotification(
                            story.getUser(),
                            currentUser,
                            NotificationType.STORY_VIEW,
                            "New Story View",
                            currentUser.getDisplayName() + " viewed your story",
                            String.valueOf(story.getId()),
                            "STORY"
                    );
                } catch (Exception ignored) {}
            }
        }

        return mapToResponse(story, currentUser);
    }

    @Transactional(readOnly = true)
    public List<StoryViewerResponse> getStoryViewers(User currentUser, Long storyId) {
        ThoughtStory story = storyRepository.findById(storyId)
                .orElseThrow(() -> new ResourceNotFoundException("Story not found with id: " + storyId));

        return storyViewRepository.findByStoryOrderByViewedAtDesc(story)
                .stream()
                .map(v -> StoryViewerResponse.builder()
                        .id(v.getId())
                        .userId(v.getViewer().getId())
                        .username(v.getViewer().getUsername())
                        .displayName(v.getViewer().getDisplayName())
                        .avatarUrl(v.getViewer().getAvatarUrl())
                        .isVerified(v.getViewer().getIsVerified())
                        .viewedAt(v.getViewedAt())
                        .build())
                .toList();
    }

    @Transactional
    public void deleteStory(User currentUser, Long storyId) {
        ThoughtStory story = storyRepository.findById(storyId)
                .orElseThrow(() -> new ResourceNotFoundException("Story not found with id: " + storyId));

        if (!story.getUser().getId().equals(currentUser.getId())) {
            throw new BadRequestException("You can only delete your own stories");
        }

        storyViewRepository.deleteByStory(story);
        storyRepository.delete(story);
    }

    public StoryResponse mapToResponse(ThoughtStory story, User currentUser) {
        boolean isMe = story.getUser().getId().equals(currentUser.getId());
        boolean viewed = isMe || storyViewRepository.existsByStoryAndViewer(story, currentUser);

        return StoryResponse.builder()
                .id(story.getId())
                .userId(story.getUser().getId())
                .username(story.getUser().getUsername())
                .displayName(story.getUser().getDisplayName())
                .avatarUrl(story.getUser().getAvatarUrl())
                .isVerified(story.getUser().getIsVerified())
                .message(story.getMessage())
                .mediaUrl(story.getMediaUrl())
                .mediaType(story.getMediaType())
                .privacy(story.getPrivacy())
                .musicTrackId(story.getMusicTrackId())
                .musicTitle(story.getMusicTitle())
                .musicArtist(story.getMusicArtist())
                .musicAlbumArt(story.getMusicAlbumArt())
                .musicPreviewUrl(story.getMusicPreviewUrl())
                .musicDuration(story.getMusicDuration())
                .backgroundGradient(story.getBackgroundGradient())
                .viewCount(story.getViewCount())
                .expiresAt(story.getExpiresAt())
                .createdAt(story.getCreatedAt())
                .isViewedByMe(viewed)
                .isMyStory(isMe)
                .build();
    }
}
