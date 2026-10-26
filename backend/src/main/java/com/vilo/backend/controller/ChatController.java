package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.ConversationResponse;
import com.vilo.backend.dto.MessageResponse;
import com.vilo.backend.dto.SendMessageRequest;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.ChatService;
import com.vilo.backend.service.FileStorageService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.MediaType;
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

    @PostMapping("/{userId}/read")
    public ResponseEntity<ApiResponse<Void>> markMessagesAsRead(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long userId
    ) {
        chatService.markMessagesAsRead(currentUser, userId);
        return ResponseEntity.ok(ApiResponse.ok("Messages marked as seen", null));
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

    @PostMapping(value = "/{userId}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<String>> uploadChatImage(
            @PathVariable Long userId,
            @RequestPart("file") MultipartFile file
    ) {
        String mediaUrl = fileStorageService.storeFile(file, "photos");
        return ResponseEntity.ok(ApiResponse.ok("Chat image uploaded successfully", mediaUrl));
    }

    @DeleteMapping("/{userId}")
    public ResponseEntity<ApiResponse<Void>> deleteConversation(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long userId
    ) {
        chatService.deleteConversation(currentUser, userId);
        return ResponseEntity.ok(ApiResponse.ok("Conversation deleted successfully", null));
    }

    @DeleteMapping("/messages/{messageId}")
    public ResponseEntity<ApiResponse<Void>> deleteMessage(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long messageId,
            @RequestParam(defaultValue = "false") boolean forEveryone
    ) {
        chatService.deleteMessage(currentUser, messageId, forEveryone);
        return ResponseEntity.ok(ApiResponse.ok(forEveryone ? "Message removed for everyone" : "Message removed for you", null));
    }

    @PostMapping("/messages/{messageId}/remove-for-me")
    public ResponseEntity<ApiResponse<Void>> removeMessageForMe(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long messageId
    ) {
        chatService.deleteMessageForMe(currentUser, messageId);
        return ResponseEntity.ok(ApiResponse.ok("Message removed for you", null));
    }

    @PostMapping("/messages/{messageId}/remove-for-everyone")
    public ResponseEntity<ApiResponse<MessageResponse>> removeMessageForEveryone(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long messageId
    ) {
        MessageResponse response = chatService.deleteMessageForEveryone(currentUser, messageId);
        return ResponseEntity.ok(ApiResponse.ok("Message removed for everyone", response));
    }
}
