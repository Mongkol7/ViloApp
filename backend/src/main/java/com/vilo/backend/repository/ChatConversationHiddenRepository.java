package com.vilo.backend.repository;

import com.vilo.backend.entity.ChatConversationHiddenEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface ChatConversationHiddenRepository extends JpaRepository<ChatConversationHiddenEntity, Long> {
    Optional<ChatConversationHiddenEntity> findByThreadIdAndUserId(String threadId, Long userId);
    List<ChatConversationHiddenEntity> findByUserId(Long userId);
    void deleteByThreadIdAndUserId(String threadId, Long userId);
}
