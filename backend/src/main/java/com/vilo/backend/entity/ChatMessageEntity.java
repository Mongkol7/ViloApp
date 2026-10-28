package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "chat_messages")
public class ChatMessageEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "thread_id", nullable = false, length = 100)
    private String threadId;

    @Column(name = "recipient_handle", nullable = false, length = 100)
    private String recipientHandle;

    @Column(name = "message_text", nullable = false, columnDefinition = "TEXT")
    private String messageText;

    @Column(name = "product_title", length = 255)
    private String productTitle;

    @Column(name = "order_reference", length = 100)
    private String orderReference;

    @Column(name = "product_price", length = 50)
    private String productPrice;

    @Column(name = "image_url", columnDefinition = "TEXT")
    private String imageUrl;

    @Column(name = "content_type", length = 20)
    private String contentType = "TEXT";

    @Column(name = "link_url", columnDefinition = "TEXT")
    private String linkUrl;

    @Column(name = "shared_video_id")
    private Long sharedVideoId;

    @Column(name = "shared_video_url", columnDefinition = "TEXT")
    private String sharedVideoUrl;

    @Column(name = "shared_video_thumbnail_url", columnDefinition = "TEXT")
    private String sharedVideoThumbnailUrl;

    @Column(name = "shared_video_creator", length = 150)
    private String sharedVideoCreator;

    @Column(name = "shared_video_caption", columnDefinition = "TEXT")
    private String sharedVideoCaption;

    @Column(name = "deleted_for_everyone", nullable = false)
    private Boolean deletedForEveryone = false;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "is_me", nullable = false)
    private Boolean isMe = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    public ChatMessageEntity() {}

    public ChatMessageEntity(Long id, User user, String threadId, String recipientHandle, String messageText, String productTitle, String productPrice, Boolean isMe, Instant createdAt) {
        this(id, user, threadId, recipientHandle, messageText, productTitle, productPrice, null, isMe, createdAt);
    }

    public ChatMessageEntity(Long id, User user, String threadId, String recipientHandle, String messageText, String productTitle, String productPrice, String imageUrl, Boolean isMe, Instant createdAt) {
        this.id = id;
        this.user = user;
        this.threadId = threadId;
        this.recipientHandle = recipientHandle;
        this.messageText = messageText;
        this.productTitle = productTitle;
        this.productPrice = productPrice;
        this.imageUrl = imageUrl;
        this.isMe = isMe;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getThreadId() {
        return threadId;
    }

    public void setThreadId(String threadId) {
        this.threadId = threadId;
    }

    public String getRecipientHandle() {
        return recipientHandle;
    }

    public void setRecipientHandle(String recipientHandle) {
        this.recipientHandle = recipientHandle;
    }

    public String getMessageText() {
        return messageText;
    }

    public void setMessageText(String messageText) {
        this.messageText = messageText;
    }

    public String getProductTitle() {
        return productTitle;
    }

    public void setProductTitle(String productTitle) {
        this.productTitle = productTitle;
    }

    public String getOrderReference() {
        return orderReference;
    }

    public void setOrderReference(String orderReference) {
        this.orderReference = orderReference;
    }

    public String getProductPrice() {
        return productPrice;
    }

    public void setProductPrice(String productPrice) {
        this.productPrice = productPrice;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public String getLinkUrl() {
        return linkUrl;
    }

    public void setLinkUrl(String linkUrl) {
        this.linkUrl = linkUrl;
    }

    public Long getSharedVideoId() {
        return sharedVideoId;
    }

    public void setSharedVideoId(Long sharedVideoId) {
        this.sharedVideoId = sharedVideoId;
    }

    public String getSharedVideoUrl() {
        return sharedVideoUrl;
    }

    public void setSharedVideoUrl(String sharedVideoUrl) {
        this.sharedVideoUrl = sharedVideoUrl;
    }

    public String getSharedVideoThumbnailUrl() {
        return sharedVideoThumbnailUrl;
    }

    public void setSharedVideoThumbnailUrl(String sharedVideoThumbnailUrl) {
        this.sharedVideoThumbnailUrl = sharedVideoThumbnailUrl;
    }

    public String getSharedVideoCreator() {
        return sharedVideoCreator;
    }

    public void setSharedVideoCreator(String sharedVideoCreator) {
        this.sharedVideoCreator = sharedVideoCreator;
    }

    public String getSharedVideoCaption() {
        return sharedVideoCaption;
    }

    public void setSharedVideoCaption(String sharedVideoCaption) {
        this.sharedVideoCaption = sharedVideoCaption;
    }

    public Boolean getDeletedForEveryone() {
        return deletedForEveryone;
    }

    public void setDeletedForEveryone(Boolean deletedForEveryone) {
        this.deletedForEveryone = deletedForEveryone;
    }

    public Instant getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(Instant deletedAt) {
        this.deletedAt = deletedAt;
    }

    public Boolean getIsMe() {
        return isMe;
    }

    public void setIsMe(Boolean isMe) {
        this.isMe = isMe;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
