package com.vilo.backend.service;

import com.vilo.backend.dto.ChatMessageRequest;
import com.vilo.backend.dto.ChatMessageResponse;
import com.vilo.backend.entity.ChatMessageEntity;
import com.vilo.backend.entity.User;
import com.vilo.backend.repository.ChatMessageRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;

    public ChatService(ChatMessageRepository chatMessageRepository) {
        this.chatMessageRepository = chatMessageRepository;
    }

    @Transactional
    public ChatMessageResponse saveMessage(User currentUser, ChatMessageRequest request) {
        ChatMessageEntity entity = new ChatMessageEntity();
        entity.setUser(currentUser);
        entity.setThreadId(request.getThreadId());
        entity.setRecipientHandle(request.getRecipientHandle());
        entity.setMessageText(request.getMessageText());
        entity.setProductTitle(request.getProductTitle());
        entity.setProductPrice(request.getProductPrice());
        entity.setIsMe(true);

        ChatMessageEntity saved = chatMessageRepository.save(entity);
        return ChatMessageResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<ChatMessageResponse> getMessages(User currentUser) {
        return chatMessageRepository.findByUserIdOrderByCreatedAtAsc(currentUser.getId())
                .stream()
                .map(ChatMessageResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ChatMessageResponse> getMessagesByThread(User currentUser, String threadId) {
        return chatMessageRepository.findByUserIdAndThreadIdOrderByCreatedAtAsc(currentUser.getId(), threadId)
                .stream()
                .map(ChatMessageResponse::fromEntity)
                .collect(Collectors.toList());
    }
}
