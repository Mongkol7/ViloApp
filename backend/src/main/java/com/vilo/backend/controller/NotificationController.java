package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.NotificationResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {
    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getNotifications(
            @AuthenticationPrincipal User currentUser,
            @RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(ApiResponse.ok("Notifications retrieved", notificationService.getForUser(currentUser, limit)));
    }

    @PatchMapping("/{notificationId}/read")
    public ResponseEntity<ApiResponse<NotificationResponse>> markRead(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long notificationId) {
        return ResponseEntity.ok(ApiResponse.ok("Notification marked as read",
                notificationService.markRead(currentUser, notificationId)));
    }

    @PostMapping("/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllRead(@AuthenticationPrincipal User currentUser) {
        notificationService.markAllRead(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Notifications marked as read", null));
    }
}
