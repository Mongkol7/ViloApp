package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.ChatMessageRequest;
import com.vilo.backend.dto.ChatMessageResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.ChatService;
import com.vilo.backend.service.FileStorageService;
import com.vilo.backend.exception.BadRequestException;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/v1/chats")
public class ChatController {

    private final ChatService chatService;
    private final FileStorageService fileStorageService;

    public ChatController(ChatService chatService, FileStorageService fileStorageService) {
        this.chatService = chatService;
        this.fileStorageService = fileStorageService;
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

    @DeleteMapping("/messages/{messageId}")
    public ResponseEntity<ApiResponse<ChatMessageResponse>> deleteMessage(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long messageId,
            @RequestParam(defaultValue = "ME") String scope
    ) {
        return ResponseEntity.ok(ApiResponse.ok("Message deletion updated",
                chatService.deleteMessage(currentUser, messageId, scope)));
    }

    @DeleteMapping("/conversations/{threadId}")
    public ResponseEntity<ApiResponse<Void>> hideConversation(
            @AuthenticationPrincipal User currentUser,
            @PathVariable String threadId
    ) {
        chatService.hideConversation(currentUser, threadId);
        return ResponseEntity.ok(ApiResponse.ok("Conversation hidden", null));
    }

    @PostMapping("/media")
    public ResponseEntity<ApiResponse<String>> uploadMedia(
            @AuthenticationPrincipal User currentUser,
            @RequestParam("file") MultipartFile file
    ) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Photo cannot be empty");
        }
        if (file.getSize() > 10L * 1024L * 1024L) {
            throw new BadRequestException("Photo must be 10 MB or smaller");
        }
        String contentType = file.getContentType() == null ? "" : file.getContentType().toLowerCase();
        if (!contentType.startsWith("image/")) {
            throw new BadRequestException("Only image files are supported");
        }
        return ResponseEntity.ok(ApiResponse.ok("Chat photo uploaded",
                fileStorageService.storeFile(file, "chat")));
    }
}
