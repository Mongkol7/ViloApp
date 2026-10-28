package com.vilo.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "recipient_id", nullable = false)
    private Long recipientId;

    @Column(name = "actor_id", nullable = false)
    private Long actorId;

    @Column(name = "notification_type", nullable = false, length = 20)
    private String type;

    @Column(name = "video_id")
    private Long videoId;

    @Column(name = "comment_id")
    private Long commentId;

    @Column(name = "target_user_id")
    private Long targetUserId;

    @Column(name = "comment_excerpt", length = 240)
    private String commentExcerpt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "read_at")
    private Instant readAt;

    public Notification() {}

    public Notification(Long recipientId, Long actorId, String type, Long videoId,
                        Long commentId, Long targetUserId, String commentExcerpt) {
        this.recipientId = recipientId;
        this.actorId = actorId;
        this.type = type;
        this.videoId = videoId;
        this.commentId = commentId;
        this.targetUserId = targetUserId;
        this.commentExcerpt = commentExcerpt;
        this.createdAt = Instant.now();
    }

    @jakarta.persistence.PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public Long getId() { return id; }
    public Long getRecipientId() { return recipientId; }
    public Long getActorId() { return actorId; }
    public String getType() { return type; }
    public Long getVideoId() { return videoId; }
    public Long getCommentId() { return commentId; }
    public Long getTargetUserId() { return targetUserId; }
    public String getCommentExcerpt() { return commentExcerpt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getReadAt() { return readAt; }
    public void setReadAt(Instant readAt) { this.readAt = readAt; }
}
