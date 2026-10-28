package com.vilo.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class ChatMessageRequest {

    @NotBlank(message = "threadId is required")
    private String threadId;

    @NotBlank(message = "recipientHandle is required")
    private String recipientHandle;

    @NotBlank(message = "messageText is required")
    private String messageText;

    private String productTitle;
    private String orderReference;
    private String productPrice;
    private String imageUrl;
    private String contentType;
    private String linkUrl;
    private Long sharedVideoId;
    private String sharedVideoUrl;
    private String sharedVideoThumbnailUrl;
    private String sharedVideoCreator;
    private String sharedVideoCaption;

    public ChatMessageRequest() {}

    public ChatMessageRequest(String threadId, String recipientHandle, String messageText, String productTitle, String productPrice) {
        this.threadId = threadId;
        this.recipientHandle = recipientHandle;
        this.messageText = messageText;
        this.productTitle = productTitle;
        this.productPrice = productPrice;
    }

    public ChatMessageRequest(String threadId, String recipientHandle, String messageText, String productTitle, String productPrice, String imageUrl) {
        this.threadId = threadId;
        this.recipientHandle = recipientHandle;
        this.messageText = messageText;
        this.productTitle = productTitle;
        this.productPrice = productPrice;
        this.imageUrl = imageUrl;
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

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public String getLinkUrl() { return linkUrl; }
    public void setLinkUrl(String linkUrl) { this.linkUrl = linkUrl; }

    public Long getSharedVideoId() { return sharedVideoId; }
    public void setSharedVideoId(Long sharedVideoId) { this.sharedVideoId = sharedVideoId; }

    public String getSharedVideoUrl() { return sharedVideoUrl; }
    public void setSharedVideoUrl(String sharedVideoUrl) { this.sharedVideoUrl = sharedVideoUrl; }

    public String getSharedVideoThumbnailUrl() { return sharedVideoThumbnailUrl; }
    public void setSharedVideoThumbnailUrl(String sharedVideoThumbnailUrl) { this.sharedVideoThumbnailUrl = sharedVideoThumbnailUrl; }

    public String getSharedVideoCreator() { return sharedVideoCreator; }
    public void setSharedVideoCreator(String sharedVideoCreator) { this.sharedVideoCreator = sharedVideoCreator; }

    public String getSharedVideoCaption() { return sharedVideoCaption; }
    public void setSharedVideoCaption(String sharedVideoCaption) { this.sharedVideoCaption = sharedVideoCaption; }
}
