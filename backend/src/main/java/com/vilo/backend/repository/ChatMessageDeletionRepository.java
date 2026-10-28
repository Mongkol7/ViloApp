package com.vilo.backend.repository;

import com.vilo.backend.entity.ChatMessageDeletionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface ChatMessageDeletionRepository extends JpaRepository<ChatMessageDeletionEntity, Long> {
    boolean existsByMessageIdAndUserId(Long messageId, Long userId);
    List<ChatMessageDeletionEntity> findByMessageIdInAndUserId(Collection<Long> messageIds, Long userId);
}
