package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.UpdateProfileRequest;
import com.vilo.backend.dto.UserResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

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

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable Long id) {
        UserResponse response = userService.getUserById(id);
        return ResponseEntity.ok(ApiResponse.ok("User profile retrieved", response));
    }

    @PostMapping("/{id}/follow")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleFollow(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long id
    ) {
        boolean isFollowing = userService.toggleFollow(currentUser, id);
        String actionMessage = isFollowing ? "Followed successfully" : "Unfollowed successfully";
        return ResponseEntity.ok(ApiResponse.ok(actionMessage, Map.of("following", isFollowing, "userId", id)));
    }
}
