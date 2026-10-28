package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.UpdateProfileRequest;
import com.vilo.backend.dto.UserResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;
    private final com.vilo.backend.service.VideoService videoService;
    private final com.vilo.backend.service.SoundService soundService;

    public UserController(UserService userService,
                          com.vilo.backend.service.VideoService videoService,
                          com.vilo.backend.service.SoundService soundService) {
        this.userService = userService;
        this.videoService = videoService;
        this.soundService = soundService;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentUser(@AuthenticationPrincipal User currentUser) {
        UserResponse response = userService.getProfile(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("User profile retrieved", response));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody UpdateProfileRequest request
    ) {
        UserResponse response = userService.updateProfile(currentUser, request);
        return ResponseEntity.ok(ApiResponse.ok("Profile updated successfully", response));
    }

    @GetMapping("/suggestions")
    public ResponseEntity<ApiResponse<List<UserResponse>>> getSuggestedUsers(
            @AuthenticationPrincipal User currentUser
    ) {
        List<UserResponse> suggestions = userService.getSuggestedUsers(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Suggested users retrieved", suggestions));
    }

    @GetMapping("/{identifier}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserByIdOrUsername(
            @PathVariable String identifier,
            @AuthenticationPrincipal User currentUser
    ) {
        UserResponse response = userService.getUserByIdOrUsername(identifier, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("User profile retrieved", response));
    }

    @GetMapping("/{identifier}/followers")
    public ResponseEntity<ApiResponse<List<UserResponse>>> getFollowers(
            @PathVariable String identifier,
            @AuthenticationPrincipal User currentUser
    ) {
        Long id = userService.resolveUserId(identifier);
        List<UserResponse> followers = userService.getFollowers(id, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Followers retrieved", followers));
    }

    @GetMapping("/{identifier}/following")
    public ResponseEntity<ApiResponse<List<UserResponse>>> getFollowing(
            @PathVariable String identifier,
            @AuthenticationPrincipal User currentUser
    ) {
        Long id = userService.resolveUserId(identifier);
        List<UserResponse> following = userService.getFollowing(id, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Following retrieved", following));
    }

    @PostMapping("/{identifier}/follow")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleFollow(
            @AuthenticationPrincipal User currentUser,
            @PathVariable String identifier
    ) {
        Long id = userService.resolveUserId(identifier);
        boolean isFollowing = userService.toggleFollow(currentUser, id);
        String actionMessage = isFollowing ? "Followed successfully" : "Unfollowed successfully";
        return ResponseEntity.ok(ApiResponse.ok(actionMessage, Map.of("following", isFollowing, "userId", id)));
    }

    @PutMapping("/{identifier}/follow")
    public ResponseEntity<ApiResponse<Map<String, Object>>> follow(
            @AuthenticationPrincipal User currentUser,
            @PathVariable String identifier
    ) {
        Long id = userService.resolveUserId(identifier);
        boolean isFollowing = userService.follow(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Followed successfully",
                Map.of("following", isFollowing, "userId", id)));
    }

    @DeleteMapping("/{identifier}/follow")
    public ResponseEntity<ApiResponse<Map<String, Object>>> unfollow(
            @AuthenticationPrincipal User currentUser,
            @PathVariable String identifier
    ) {
        Long id = userService.resolveUserId(identifier);
        userService.unfollow(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Unfollowed successfully", Map.of("following", false, "userId", id)));
    }

    @GetMapping("/{identifier}/sounds")
    public ResponseEntity<ApiResponse<List<com.vilo.backend.dto.SoundResponse>>> getUserSounds(
            @PathVariable String identifier
    ) {
        Long id = null;
        try {
            id = Long.parseLong(identifier);
        } catch (NumberFormatException ignored) {}
        List<com.vilo.backend.dto.SoundResponse> sounds = soundService.getUserSounds(id, identifier);
        return ResponseEntity.ok(ApiResponse.ok("User sounds retrieved", sounds));
    }

    @GetMapping("/{identifier}/videos")
    public ResponseEntity<ApiResponse<List<com.vilo.backend.dto.VideoResponse>>> getUserVideos(
            @PathVariable String identifier,
            @AuthenticationPrincipal User currentUser
    ) {
        List<com.vilo.backend.dto.VideoResponse> videos = videoService.getUserVideos(identifier, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("User videos retrieved", videos));
    }

    @GetMapping("/{identifier}/saved")
    public ResponseEntity<ApiResponse<List<com.vilo.backend.dto.VideoResponse>>> getUserSavedVideos(
            @PathVariable String identifier
    ) {
        Long id = userService.resolveUserId(identifier);
        List<com.vilo.backend.dto.VideoResponse> savedVideos = videoService.getSavedVideos(id);
        return ResponseEntity.ok(ApiResponse.ok("User saved videos retrieved", savedVideos));
    }

    @GetMapping("/{identifier}/liked")
    public ResponseEntity<ApiResponse<List<com.vilo.backend.dto.VideoResponse>>> getUserLikedVideos(
            @PathVariable String identifier
    ) {
        Long id = userService.resolveUserId(identifier);
        List<com.vilo.backend.dto.VideoResponse> likedVideos = videoService.getLikedVideos(id);
        return ResponseEntity.ok(ApiResponse.ok("User liked videos retrieved", likedVideos));
    }
}
