package com.vilo.backend.repository;

import com.vilo.backend.entity.ChatMessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessageEntity, Long> {
    List<ChatMessageEntity> findByUserIdOrderByCreatedAtAsc(Long userId);
    List<ChatMessageEntity> findByUserIdAndThreadIdOrderByCreatedAtAsc(Long userId, String threadId);

    @Query("SELECT m FROM ChatMessageEntity m JOIN FETCH m.user WHERE m.user.id = :userId OR LOWER(m.recipientHandle) IN :handles ORDER BY m.createdAt ASC")
    List<ChatMessageEntity> findUserMessages(
            @Param("userId") Long userId,
            @Param("handles") java.util.Collection<String> handles
    );

    @Query("SELECT m FROM ChatMessageEntity m JOIN FETCH m.user WHERE m.threadId = :threadId AND (m.user.id = :userId OR LOWER(m.recipientHandle) IN :handles) ORDER BY m.createdAt ASC")
    List<ChatMessageEntity> findThreadMessages(
            @Param("threadId") String threadId,
            @Param("userId") Long userId,
            @Param("handles") java.util.Collection<String> handles
    );
}
