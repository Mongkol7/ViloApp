package com.vilo.backend.entity;

import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "chat_conversation_hides",
        uniqueConstraints = @UniqueConstraint(name = "uk_chat_conversation_hide_user", columnNames = {"thread_id", "user_id"}))
public class ChatConversationHiddenEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "thread_id", nullable = false, length = 100)
    private String threadId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "hidden_at", nullable = false)
    private Instant hiddenAt;

    public ChatConversationHiddenEntity() {}

    public ChatConversationHiddenEntity(String threadId, Long userId, Instant hiddenAt) {
        this.threadId = threadId;
        this.userId = userId;
        this.hiddenAt = hiddenAt;
    }

    public Long getId() { return id; }
    public String getThreadId() { return threadId; }
    public Long getUserId() { return userId; }
    public Instant getHiddenAt() { return hiddenAt; }
    public void setHiddenAt(Instant hiddenAt) { this.hiddenAt = hiddenAt; }
}
