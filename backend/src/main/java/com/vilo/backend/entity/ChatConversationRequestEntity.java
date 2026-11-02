package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Entity
@Table(name = "chat_conversation_requests",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_chat_request_thread_recipient",
                columnNames = {"thread_id", "recipient_user_id"}))
public class ChatConversationRequestEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "thread_id", nullable = false, length = 100)
    private String threadId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_user_id", nullable = false)
    private User sender;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_user_id", nullable = false)
    private User recipient;

    @Column(nullable = false, length = 20)
    private String status = "PENDING";

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;

    public ChatConversationRequestEntity() {}

    public ChatConversationRequestEntity(String threadId, User sender, User recipient) {
        this.threadId = threadId;
        this.sender = sender;
        this.recipient = recipient;
        this.status = "PENDING";
    }

    public Long getId() { return id; }
    public String getThreadId() { return threadId; }
    public User getSender() { return sender; }
    public User getRecipient() { return recipient; }
    public String getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setStatus(String status) { this.status = status; }
}
