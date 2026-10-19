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

    public UserController(UserService userService) {
        this.userService = userService;
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

    @DeleteMapping("/{identifier}/follow")
    public ResponseEntity<ApiResponse<Map<String, Object>>> unfollow(
            @AuthenticationPrincipal User currentUser,
            @PathVariable String identifier
    ) {
        Long id = userService.resolveUserId(identifier);
        userService.unfollow(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Unfollowed successfully", Map.of("following", false, "userId", id)));
    }
}
