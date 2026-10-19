package com.vilo.backend.dto;

import java.time.Instant;

public class ConversationResponse {

    private Long id;
    private Long otherUserId;
    private String otherUsername;
    private String otherDisplayName;
    private String otherAvatarUrl;
    private Boolean isOtherVerified;
    private String lastMessageContent;
    private Long lastMessageSenderId;
    private Instant lastMessageTime;
    private Long unreadCount;
    private Boolean isFollowing;
    private Boolean followsYou;
    private Boolean isFriend;

    public ConversationResponse() {
    }

    public ConversationResponse(Long id, Long otherUserId, String otherUsername, String otherDisplayName,
                                String otherAvatarUrl, Boolean isOtherVerified, String lastMessageContent,
                                Long lastMessageSenderId, Instant lastMessageTime, Long unreadCount) {
        this(id, otherUserId, otherUsername, otherDisplayName, otherAvatarUrl, isOtherVerified,
                lastMessageContent, lastMessageSenderId, lastMessageTime, unreadCount, false, false, false);
    }

    public ConversationResponse(Long id, Long otherUserId, String otherUsername, String otherDisplayName,
                                String otherAvatarUrl, Boolean isOtherVerified, String lastMessageContent,
                                Long lastMessageSenderId, Instant lastMessageTime, Long unreadCount,
                                Boolean isFollowing, Boolean followsYou, Boolean isFriend) {
        this.id = id;
        this.otherUserId = otherUserId;
        this.otherUsername = otherUsername;
        this.otherDisplayName = otherDisplayName;
        this.otherAvatarUrl = otherAvatarUrl;
        this.isOtherVerified = isOtherVerified;
        this.lastMessageContent = lastMessageContent;
        this.lastMessageSenderId = lastMessageSenderId;
        this.lastMessageTime = lastMessageTime;
        this.unreadCount = unreadCount;
        this.isFollowing = isFollowing;
        this.followsYou = followsYou;
        this.isFriend = isFriend;
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

    public Long getOtherUserId() {
        return otherUserId;
    }

    public void setOtherUserId(Long otherUserId) {
        this.otherUserId = otherUserId;
    }

    public String getOtherUsername() {
        return otherUsername;
    }

    public void setOtherUsername(String otherUsername) {
        this.otherUsername = otherUsername;
    }

    public String getOtherDisplayName() {
        return otherDisplayName;
    }

    public void setOtherDisplayName(String otherDisplayName) {
        this.otherDisplayName = otherDisplayName;
    }

    public String getOtherAvatarUrl() {
        return otherAvatarUrl;
    }

    public void setOtherAvatarUrl(String otherAvatarUrl) {
        this.otherAvatarUrl = otherAvatarUrl;
    }

    public Boolean getIsOtherVerified() {
        return isOtherVerified;
    }

    public void setIsOtherVerified(Boolean isOtherVerified) {
        this.isOtherVerified = isOtherVerified;
    }

    public String getLastMessageContent() {
        return lastMessageContent;
    }

    public void setLastMessageContent(String lastMessageContent) {
        this.lastMessageContent = lastMessageContent;
    }

    public Long getLastMessageSenderId() {
        return lastMessageSenderId;
    }

    public void setLastMessageSenderId(Long lastMessageSenderId) {
        this.lastMessageSenderId = lastMessageSenderId;
    }

    public Instant getLastMessageTime() {
        return lastMessageTime;
    }

    public void setLastMessageTime(Instant lastMessageTime) {
        this.lastMessageTime = lastMessageTime;
    }

    public Long getUnreadCount() {
        return unreadCount;
    }

    public void setUnreadCount(Long unreadCount) {
        this.unreadCount = unreadCount;
    }

    public Boolean getIsFollowing() {
        return isFollowing;
    }

    public void setIsFollowing(Boolean isFollowing) {
        this.isFollowing = isFollowing;
    }

    public Boolean getFollowsYou() {
        return followsYou;
    }

    public void setFollowsYou(Boolean followsYou) {
        this.followsYou = followsYou;
    }

    public Boolean getIsFriend() {
        return isFriend;
    }

    public void setIsFriend(Boolean isFriend) {
        this.isFriend = isFriend;
    }

    public static class Builder {
        private Long id;
        private Long otherUserId;
        private String otherUsername;
        private String otherDisplayName;
        private String otherAvatarUrl;
        private Boolean isOtherVerified;
        private String lastMessageContent;
        private Long lastMessageSenderId;
        private Instant lastMessageTime;
        private Long unreadCount;
        private Boolean isFollowing = false;
        private Boolean followsYou = false;
        private Boolean isFriend = false;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder otherUserId(Long otherUserId) {
            this.otherUserId = otherUserId;
            return this;
        }

        public Builder otherUsername(String otherUsername) {
            this.otherUsername = otherUsername;
            return this;
        }

        public Builder otherDisplayName(String otherDisplayName) {
            this.otherDisplayName = otherDisplayName;
            return this;
        }

        public Builder otherAvatarUrl(String otherAvatarUrl) {
            this.otherAvatarUrl = otherAvatarUrl;
            return this;
        }

        public Builder isOtherVerified(Boolean isOtherVerified) {
            this.isOtherVerified = isOtherVerified;
            return this;
        }

        public Builder lastMessageContent(String lastMessageContent) {
            this.lastMessageContent = lastMessageContent;
            return this;
        }

        public Builder lastMessageSenderId(Long lastMessageSenderId) {
            this.lastMessageSenderId = lastMessageSenderId;
            return this;
        }

        public Builder lastMessageTime(Instant lastMessageTime) {
            this.lastMessageTime = lastMessageTime;
            return this;
        }

        public Builder unreadCount(Long unreadCount) {
            this.unreadCount = unreadCount;
            return this;
        }

        public Builder isFollowing(Boolean isFollowing) {
            this.isFollowing = isFollowing;
            return this;
        }

        public Builder followsYou(Boolean followsYou) {
            this.followsYou = followsYou;
            return this;
        }

        public Builder isFriend(Boolean isFriend) {
            this.isFriend = isFriend;
            return this;
        }

        public ConversationResponse build() {
            return new ConversationResponse(id, otherUserId, otherUsername, otherDisplayName, otherAvatarUrl,
                    isOtherVerified, lastMessageContent, lastMessageSenderId, lastMessageTime, unreadCount,
                    isFollowing, followsYou, isFriend);
        }
    }
}
