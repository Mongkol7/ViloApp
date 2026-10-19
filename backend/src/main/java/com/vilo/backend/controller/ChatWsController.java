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
}
