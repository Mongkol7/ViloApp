package com.vilo.backend.dto;

import com.vilo.backend.entity.ChatMessageEntity;

import java.time.Instant;

public class ChatMessageResponse {

    private Long id;
    private String threadId;
    private String recipientHandle;
    private String messageText;
    private String productTitle;
    private String productPrice;
    private Boolean isMe;
    private Instant createdAt;

    public ChatMessageResponse() {}

    public ChatMessageResponse(Long id, String threadId, String recipientHandle, String messageText, String productTitle, String productPrice, Boolean isMe, Instant createdAt) {
        this.id = id;
        this.threadId = threadId;
        this.recipientHandle = recipientHandle;
        this.messageText = messageText;
        this.productTitle = productTitle;
        this.productPrice = productPrice;
        this.isMe = isMe;
        this.createdAt = createdAt;
    }

    public static ChatMessageResponse fromEntity(ChatMessageEntity entity) {
        return new ChatMessageResponse(
                entity.getId(),
                entity.getThreadId(),
                entity.getRecipientHandle(),
                entity.getMessageText(),
                entity.getProductTitle(),
                entity.getProductPrice(),
                entity.getIsMe(),
                entity.getCreatedAt()
        );
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
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

    public String getProductPrice() {
        return productPrice;
    }

    public void setProductPrice(String productPrice) {
        this.productPrice = productPrice;
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
