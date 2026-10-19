package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.ConversationResponse;
import com.vilo.backend.dto.MessageResponse;
import com.vilo.backend.dto.SendMessageRequest;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.ChatService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/chats")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping("/conversations")
    public ResponseEntity<ApiResponse<List<ConversationResponse>>> getConversations(
            @AuthenticationPrincipal User currentUser
    ) {
        List<ConversationResponse> conversations = chatService.getConversations(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Conversations retrieved successfully", conversations));
    }

    @GetMapping("/{userId}/messages")
    public ResponseEntity<ApiResponse<Page<MessageResponse>>> getMessagesWithUser(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size
    ) {
        Page<MessageResponse> messages = chatService.getMessagesWithUser(currentUser, userId, page, size);
        return ResponseEntity.ok(ApiResponse.ok("Messages retrieved successfully", messages));
    }

    @PostMapping("/{userId}/messages")
    public ResponseEntity<ApiResponse<MessageResponse>> sendMessage(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long userId,
            @Valid @RequestBody SendMessageRequest request
    ) {
        MessageResponse message = chatService.sendMessage(currentUser, userId, request);
        return ResponseEntity.ok(ApiResponse.ok("Message sent successfully", message));
    }
}
