package com.vilo.backend.dto;

import java.time.Instant;

public class MessageResponse {

    private Long id;
    private Long conversationId;
    private Long senderId;
    private String senderUsername;
    private String senderDisplayName;
    private String senderAvatarUrl;
    private Long recipientId;
    private String recipientUsername;
    private String content;
    private String mediaUrl;
    private Boolean isRead;
    private Boolean isMe;
    private Boolean deleted;
    private Boolean deletedForEveryone;
    private Instant createdAt;

    public MessageResponse() {
    }

    public MessageResponse(Long id, Long conversationId, Long senderId, String senderUsername,
                           String senderDisplayName, String senderAvatarUrl, Long recipientId,
                           String recipientUsername, String content, String mediaUrl,
                           Boolean isRead, Boolean isMe, Instant createdAt) {
        this.id = id;
        this.conversationId = conversationId;
        this.senderId = senderId;
        this.senderUsername = senderUsername;
        this.senderDisplayName = senderDisplayName;
        this.senderAvatarUrl = senderAvatarUrl;
        this.recipientId = recipientId;
        this.recipientUsername = recipientUsername;
        this.content = content;
        this.mediaUrl = mediaUrl;
        this.isRead = isRead;
        this.isMe = isMe;
        this.createdAt = createdAt;
    }

    public static Builder builder() {
        return new Builder();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getConversationId() {
        return conversationId;
    }

    public void setConversationId(Long conversationId) {
        this.conversationId = conversationId;
    }

    public Long getSenderId() {
        return senderId;
    }

    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }

    public String getSenderUsername() {
        return senderUsername;
    }

    public void setSenderUsername(String senderUsername) {
        this.senderUsername = senderUsername;
    }

    public String getSenderDisplayName() {
        return senderDisplayName;
    }

    public void setSenderDisplayName(String senderDisplayName) {
        this.senderDisplayName = senderDisplayName;
    }

    public String getSenderAvatarUrl() {
        return senderAvatarUrl;
    }

    public void setSenderAvatarUrl(String senderAvatarUrl) {
        this.senderAvatarUrl = senderAvatarUrl;
    }

    public Long getRecipientId() {
        return recipientId;
    }

    public void setRecipientId(Long recipientId) {
        this.recipientId = recipientId;
    }

    public String getRecipientUsername() {
        return recipientUsername;
    }

    public void setRecipientUsername(String recipientUsername) {
        this.recipientUsername = recipientUsername;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getMediaUrl() {
        return mediaUrl;
    }

    public void setMediaUrl(String mediaUrl) {
        this.mediaUrl = mediaUrl;
    }

    public Boolean getIsRead() {
        return isRead;
    }

    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
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

    public Boolean getDeleted() { return deleted; }
    public void setDeleted(Boolean deleted) { this.deleted = deleted; }

    public Boolean getDeletedForEveryone() { return deletedForEveryone; }
    public void setDeletedForEveryone(Boolean deletedForEveryone) { this.deletedForEveryone = deletedForEveryone; }

    public static class Builder {
        private Long id;
        private Long conversationId;
        private Long senderId;
        private String senderUsername;
        private String senderDisplayName;
        private String senderAvatarUrl;
        private Long recipientId;
        private String recipientUsername;
        private String content;
        private String mediaUrl;
        private Boolean isRead;
        private Boolean isMe;
        private Boolean deleted;
        private Boolean deletedForEveryone;
        private Instant createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder conversationId(Long conversationId) {
            this.conversationId = conversationId;
            return this;
        }

        public Builder senderId(Long senderId) {
            this.senderId = senderId;
            return this;
        }

        public Builder senderUsername(String senderUsername) {
            this.senderUsername = senderUsername;
            return this;
        }

        public Builder senderDisplayName(String senderDisplayName) {
            this.senderDisplayName = senderDisplayName;
            return this;
        }

        public Builder senderAvatarUrl(String senderAvatarUrl) {
            this.senderAvatarUrl = senderAvatarUrl;
            return this;
        }

        public Builder recipientId(Long recipientId) {
            this.recipientId = recipientId;
            return this;
        }

        public Builder recipientUsername(String recipientUsername) {
            this.recipientUsername = recipientUsername;
            return this;
        }

        public Builder content(String content) {
            this.content = content;
            return this;
        }

        public Builder mediaUrl(String mediaUrl) {
            this.mediaUrl = mediaUrl;
            return this;
        }

        public Builder isRead(Boolean isRead) {
            this.isRead = isRead;
            return this;
        }

        public Builder isMe(Boolean isMe) {
            this.isMe = isMe;
            return this;
        }

        public Builder deleted(Boolean deleted) {
            this.deleted = deleted;
            this.deletedForEveryone = deleted;
            return this;
        }

        public Builder deletedForEveryone(Boolean deletedForEveryone) {
            this.deletedForEveryone = deletedForEveryone;
            this.deleted = deletedForEveryone;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public MessageResponse build() {
            MessageResponse response = new MessageResponse(id, conversationId, senderId, senderUsername, senderDisplayName,
                    senderAvatarUrl, recipientId, recipientUsername, content, mediaUrl, isRead, isMe, createdAt);
            response.deleted = deleted != null ? deleted : deletedForEveryone;
            response.deletedForEveryone = deletedForEveryone != null ? deletedForEveryone : deleted;
            return response;
        }
    }
}
