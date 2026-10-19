package com.vilo.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class SendMessageRequest {

    @NotBlank(message = "Message content cannot be blank")
    @Size(max = 2000, message = "Message cannot exceed 2000 characters")
    private String content;

    private String mediaUrl;

    public SendMessageRequest() {
    }

    public SendMessageRequest(String content, String mediaUrl) {
        this.content = content;
        this.mediaUrl = mediaUrl;
    }

    public static Builder builder() {
        return new Builder();
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
        private String content;
        private String mediaUrl;

        public Builder content(String content) {
            this.content = content;
            return this;
        }

        public Builder mediaUrl(String mediaUrl) {
            this.mediaUrl = mediaUrl;
            return this;
        }

        public SendMessageRequest build() {
            return new SendMessageRequest(content, mediaUrl);
        }
    }
}
