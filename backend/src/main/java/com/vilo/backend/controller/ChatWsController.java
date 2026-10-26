package com.vilo.backend.controller;

import com.vilo.backend.dto.MessageResponse;
import com.vilo.backend.dto.SendMessageRequest;
import com.vilo.backend.dto.WsChatMessageRequest;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.service.ChatService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.Map;

@Controller
public class ChatWsController {

    private static final Logger log = LoggerFactory.getLogger(ChatWsController.class);

    private final ChatService chatService;
    private final UserRepository userRepository;

    public ChatWsController(ChatService chatService, UserRepository userRepository) {
        this.chatService = chatService;
        this.userRepository = userRepository;
    }

    @MessageMapping("/chat.sendMessage")
    public MessageResponse handleSendMessage(Principal principal, @Payload WsChatMessageRequest payload) {
        if (principal == null) {
            log.warn("Received STOMP chat message without authenticated principal");
            return null;
        }

        String username = principal.getName();
        User sender = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + username));

        SendMessageRequest request = SendMessageRequest.builder()
                .content(payload.getContent())
                .mediaUrl(payload.getMediaUrl())
                .build();

        return chatService.sendMessage(sender, payload.getRecipientId(), request);
    }

    @MessageMapping("/chat.markSeen")
    public void handleMarkSeen(Principal principal, @Payload Map<String, Object> payload) {
        if (principal == null || payload == null) return;
        try {
            String username = principal.getName();
            User currentUser = userRepository.findByUsername(username)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found: " + username));

            Object otherIdObj = payload.get("otherUserId");
            if (otherIdObj != null) {
                Long otherUserId = Long.valueOf(otherIdObj.toString());
                chatService.markMessagesAsRead(currentUser, otherUserId);
            }
        } catch (Exception ex) {
            log.warn("Error marking messages as seen via STOMP: {}", ex.getMessage());
        }
    }
}
