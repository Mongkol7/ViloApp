package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "chat_message_deletions",
        uniqueConstraints = @UniqueConstraint(name = "uk_chat_message_deletion_user", columnNames = {"message_id", "user_id"}))
public class ChatMessageDeletionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "message_id", nullable = false)
    private Long messageId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @CreationTimestamp
    @Column(name = "deleted_at", nullable = false, updatable = false)
    private Instant deletedAt;

    public ChatMessageDeletionEntity() {}

    public ChatMessageDeletionEntity(Long messageId, Long userId) {
        this.messageId = messageId;
        this.userId = userId;
    }

    public Long getId() { return id; }
    public Long getMessageId() { return messageId; }
    public Long getUserId() { return userId; }
    public Instant getDeletedAt() { return deletedAt; }
}
