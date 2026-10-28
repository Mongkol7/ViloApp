package com.vilo.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vilo.backend.entity.ChatMessageEntity;
import com.vilo.backend.entity.User;
import com.vilo.backend.repository.UserRepository;

import java.time.Instant;
import java.util.Optional;

public class ChatMessageResponse {

    private Long id;
    private String threadId;
    private String recipientHandle;
    private String senderHandle;
    private String senderDisplayName;
    private String senderAvatar;
    private String recipientDisplayName;
    private String recipientAvatar;
    private String peerUsername;
    private String peerDisplayName;
    private String peerAvatarUrl;
    private String messageText;
    private String productTitle;
    private String orderReference;
    private String productPrice;
    private String imageUrl;
    @JsonProperty("isMe")
    private Boolean isMe;
    private Instant createdAt;

    public ChatMessageResponse() {}

    public ChatMessageResponse(Long id, String threadId, String recipientHandle, String messageText, String productTitle, String productPrice, Boolean isMe, Instant createdAt) {
        this(id, threadId, recipientHandle, messageText, productTitle, productPrice, null, isMe, createdAt);
    }

    public ChatMessageResponse(Long id, String threadId, String recipientHandle, String messageText, String productTitle, String productPrice, String imageUrl, Boolean isMe, Instant createdAt) {
        this.id = id;
        this.threadId = threadId;
        this.recipientHandle = recipientHandle;
        this.messageText = messageText;
        this.productTitle = productTitle;
        this.productPrice = productPrice;
        this.imageUrl = imageUrl;
        this.isMe = isMe;
        this.createdAt = createdAt;
    }

    public static ChatMessageResponse fromEntity(ChatMessageEntity entity) {
        ChatMessageResponse res = new ChatMessageResponse(
                entity.getId(),
                entity.getThreadId(),
                entity.getRecipientHandle(),
                entity.getMessageText(),
                entity.getProductTitle(),
                entity.getProductPrice(),
                entity.getImageUrl(),
                entity.getIsMe(),
                entity.getCreatedAt()
        );
        if (entity.getUser() != null) {
            res.setSenderHandle(entity.getUser().getUsername());
            res.setSenderDisplayName(entity.getUser().getDisplayName());
            res.setSenderAvatar(entity.getUser().getAvatarUrl());
        }
        res.setPeerUsername(entity.getRecipientHandle());
        res.setOrderReference(entity.getOrderReference());
        return res;
    }

    public static ChatMessageResponse fromEntity(ChatMessageEntity entity, User currentUser, UserRepository userRepository) {
        ChatMessageResponse res = fromEntity(entity);

        boolean isMe = currentUser != null && entity.getUser() != null && entity.getUser().getId().equals(currentUser.getId());
        res.setIsMe(isMe);

        String senderHandle = entity.getUser() != null ? entity.getUser().getUsername() : null;
        String senderDisplayName = entity.getUser() != null ? entity.getUser().getDisplayName() : null;
        String senderAvatar = entity.getUser() != null ? entity.getUser().getAvatarUrl() : null;

        res.setSenderHandle(senderHandle);
        res.setSenderDisplayName(senderDisplayName);
        res.setSenderAvatar(senderAvatar);

        String rawRecipient = entity.getRecipientHandle();
        String cleanRecipient = rawRecipient != null ? rawRecipient.replace("@", "").trim() : "";
        String recipientAvatar = null;
        String recipientDisplayName = null;
        if (userRepository != null && !cleanRecipient.isEmpty()) {
            Optional<User> recipientUser = userRepository.findByUsername(cleanRecipient);
            if (recipientUser.isEmpty()) {
                recipientUser = userRepository.findByUsernameIgnoreCase(cleanRecipient);
            }
            if (recipientUser.isEmpty()) {
                java.util.List<User> byDisplay = userRepository.findByDisplayNameIgnoreCase(cleanRecipient);
                if (byDisplay.size() == 1) {
                    recipientUser = Optional.of(byDisplay.get(0));
                }
            }
            if (recipientUser.isEmpty()) {
                String lower = cleanRecipient.toLowerCase(java.util.Locale.ROOT);
                if (lower.contains("techhorizon") || lower.contains("techgear") || lower.contains("god_gear") ||
                    lower.contains("god gear") || lower.contains("master_tech") || lower.contains("master tech") ||
                    lower.contains("pulse") || lower.contains("aura") || lower.contains("vilo_deals") ||
                    lower.contains("vilo deals") || lower.contains("seller") || lower.contains("techpro")) {
                    recipientUser = userRepository.findByUsernameIgnoreCase("rithysak")
                            .or(() -> userRepository.findByUsernameIgnoreCase("mongkol"));
                }
            }
            if (recipientUser.isPresent()) {
                recipientAvatar = recipientUser.get().getAvatarUrl();
                recipientDisplayName = recipientUser.get().getDisplayName();
                if (recipientUser.get().getUsername() != null && !recipientUser.get().getUsername().isBlank()) {
                    res.setRecipientHandle(recipientUser.get().getUsername());
                }
            }
        }
        res.setRecipientAvatar(recipientAvatar);
        res.setRecipientDisplayName(recipientDisplayName);

        if (isMe) {
            String peerHandle = res.getRecipientHandle() != null ? res.getRecipientHandle() : rawRecipient;
            res.setPeerUsername(peerHandle != null ? (peerHandle.startsWith("@") ? peerHandle : "@" + peerHandle) : "@seller");
            res.setPeerDisplayName(recipientDisplayName != null && !recipientDisplayName.isEmpty() ? recipientDisplayName : peerHandle);
            res.setPeerAvatarUrl(recipientAvatar != null ? recipientAvatar : "");
        } else {
            String peerU = senderHandle != null ? (senderHandle.startsWith("@") ? senderHandle : "@" + senderHandle) : rawRecipient;
            res.setPeerUsername(peerU);
            res.setPeerDisplayName(senderDisplayName != null && !senderDisplayName.isEmpty() ? senderDisplayName : peerU);
            res.setPeerAvatarUrl(senderAvatar != null ? senderAvatar : "");
        }

        return res;
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

    public String getSenderHandle() {
        return senderHandle;
    }

    public void setSenderHandle(String senderHandle) {
        this.senderHandle = senderHandle;
    }

    public String getSenderDisplayName() {
        return senderDisplayName;
    }

    public void setSenderDisplayName(String senderDisplayName) {
        this.senderDisplayName = senderDisplayName;
    }

    public String getSenderAvatar() {
        return senderAvatar;
    }

    public void setSenderAvatar(String senderAvatar) {
        this.senderAvatar = senderAvatar;
    }

    public String getRecipientDisplayName() {
        return recipientDisplayName;
    }

    public void setRecipientDisplayName(String recipientDisplayName) {
        this.recipientDisplayName = recipientDisplayName;
    }

    public String getRecipientAvatar() {
        return recipientAvatar;
    }

    public void setRecipientAvatar(String recipientAvatar) {
        this.recipientAvatar = recipientAvatar;
    }

    public String getPeerUsername() {
        return peerUsername;
    }

    public void setPeerUsername(String peerUsername) {
        this.peerUsername = peerUsername;
    }

    public String getPeerDisplayName() {
        return peerDisplayName;
    }

    public void setPeerDisplayName(String peerDisplayName) {
        this.peerDisplayName = peerDisplayName;
    }

    public String getPeerAvatarUrl() {
        return peerAvatarUrl;
    }

    public void setPeerAvatarUrl(String peerAvatarUrl) {
        this.peerAvatarUrl = peerAvatarUrl;
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
