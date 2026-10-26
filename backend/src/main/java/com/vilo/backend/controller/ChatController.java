package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.ChatMessageRequest;
import com.vilo.backend.dto.ChatMessageResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.ChatService;
import jakarta.validation.Valid;
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

    @PostMapping("/messages")
    public ResponseEntity<ApiResponse<ChatMessageResponse>> sendMessage(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody ChatMessageRequest request
    ) {
        ChatMessageResponse response = chatService.saveMessage(currentUser, request);
        return ResponseEntity.ok(ApiResponse.ok("Message sent and saved successfully", response));
    }

    @GetMapping("/conversations")
    public ResponseEntity<ApiResponse<List<ChatMessageResponse>>> getConversations(
            @AuthenticationPrincipal User currentUser
    ) {
        List<ChatMessageResponse> messages = chatService.getMessages(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Conversations retrieved successfully", messages));
    }

    @GetMapping("/{threadId}/messages")
    public ResponseEntity<ApiResponse<List<ChatMessageResponse>>> getThreadMessages(
            @AuthenticationPrincipal User currentUser,
            @PathVariable String threadId
    ) {
        List<ChatMessageResponse> messages = chatService.getMessagesByThread(currentUser, threadId);
        return ResponseEntity.ok(ApiResponse.ok("Thread messages retrieved successfully", messages));
    }
}
