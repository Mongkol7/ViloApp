package com.vilo.backend.dto;

public class WsChatMessageRequest {

    private Long recipientId;
    private String content;
    private String mediaUrl;

    public WsChatMessageRequest() {
    }

    public WsChatMessageRequest(Long recipientId, String content, String mediaUrl) {
        this.recipientId = recipientId;
        this.content = content;
        this.mediaUrl = mediaUrl;
    }

    public static Builder builder() {
        return new Builder();
    }

    public Long getRecipientId() {
        return recipientId;
    }

    public void setRecipientId(Long recipientId) {
        this.recipientId = recipientId;
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

    public static class Builder {
        private Long recipientId;
        private String content;
        private String mediaUrl;

        public Builder recipientId(Long recipientId) {
            this.recipientId = recipientId;
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

        public WsChatMessageRequest build() {
            return new WsChatMessageRequest(recipientId, content, mediaUrl);
        }
    }
}
