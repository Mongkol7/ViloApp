package com.vilo.backend.repository;

import com.vilo.backend.entity.ChatConversationRequestEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ChatConversationRequestRepository
        extends JpaRepository<ChatConversationRequestEntity, Long> {

    Optional<ChatConversationRequestEntity> findByThreadIdAndRecipientId(
            String threadId, Long recipientId);

    Optional<ChatConversationRequestEntity> findFirstByThreadIdAndStatus(
            String threadId, String status);
}
