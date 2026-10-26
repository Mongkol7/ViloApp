package com.vilo.backend.repository;

import com.vilo.backend.entity.ChatMessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessageEntity, Long> {
    List<ChatMessageEntity> findByUserIdOrderByCreatedAtAsc(Long userId);
    List<ChatMessageEntity> findByUserIdAndThreadIdOrderByCreatedAtAsc(Long userId, String threadId);
}
