package com.vilo.backend.dto;

import jakarta.validation.constraints.Size;

public class CreateStoryRequest {

    @Size(max = 500, message = "Story message cannot exceed 500 characters")
    private String message;

    private String mediaUrl;
    private String mediaType = "TEXT"; // "TEXT", "IMAGE", "VIDEO"
    private String privacy = "PUBLIC"; // "PUBLIC", "FOLLOWERS", "FRIENDS"

    private String musicTrackId;
    private String musicTitle;
    private String musicArtist;
    private String musicAlbumArt;
    private String musicPreviewUrl;
    private Integer musicDuration;
    private String backgroundGradient;
    private Integer expiresInHours = 24;

    public CreateStoryRequest() {
    }

    public CreateStoryRequest(String message, String mediaUrl, String mediaType, String privacy,
                              String musicTrackId, String musicTitle, String musicArtist,
                              String musicAlbumArt, String musicPreviewUrl, Integer musicDuration,
                              String backgroundGradient, Integer expiresInHours) {
        this.message = message;
        this.mediaUrl = mediaUrl;
        this.mediaType = mediaType != null ? mediaType : "TEXT";
        this.privacy = privacy != null ? privacy : "PUBLIC";
        this.musicTrackId = musicTrackId;
        this.musicTitle = musicTitle;
        this.musicArtist = musicArtist;
        this.musicAlbumArt = musicAlbumArt;
        this.musicPreviewUrl = musicPreviewUrl;
        this.musicDuration = musicDuration;
        this.backgroundGradient = backgroundGradient;
        this.expiresInHours = expiresInHours != null ? expiresInHours : 24;
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getMusicTrackId() {
        return musicTrackId;
    }

    public void setMusicTrackId(String musicTrackId) {
        this.musicTrackId = musicTrackId;
    }

    public String getMusicTitle() {
        return musicTitle;
    }

    public void setMusicTitle(String musicTitle) {
        this.musicTitle = musicTitle;
    }

    public String getMusicArtist() {
        return musicArtist;
    }

    public void setMusicArtist(String musicArtist) {
        this.musicArtist = musicArtist;
    }

    public String getMusicAlbumArt() {
        return musicAlbumArt;
    }

    public void setMusicAlbumArt(String musicAlbumArt) {
        this.musicAlbumArt = musicAlbumArt;
    }

    public String getMusicPreviewUrl() {
        return musicPreviewUrl;
    }

    public void setMusicPreviewUrl(String musicPreviewUrl) {
        this.musicPreviewUrl = musicPreviewUrl;
    }

    public Integer getMusicDuration() {
        return musicDuration;
    }

    public void setMusicDuration(Integer musicDuration) {
        this.musicDuration = musicDuration;
    }

    public String getBackgroundGradient() {
        return backgroundGradient;
    }

    public void setBackgroundGradient(String backgroundGradient) {
        this.backgroundGradient = backgroundGradient;
    }

    public String getMediaUrl() {
        return mediaUrl;
    }

    public void setMediaUrl(String mediaUrl) {
        this.mediaUrl = mediaUrl;
    }

    public String getMediaType() {
        return mediaType;
    }

    public void setMediaType(String mediaType) {
        this.mediaType = mediaType;
    }

    public String getPrivacy() {
        return privacy;
    }

    public void setPrivacy(String privacy) {
        this.privacy = privacy;
    }

    public Integer getExpiresInHours() {
        return expiresInHours;
    }

    public void setExpiresInHours(Integer expiresInHours) {
        this.expiresInHours = expiresInHours;
    }

    public static class Builder {
        private String message;
        private String mediaUrl;
        private String mediaType = "TEXT";
        private String privacy = "PUBLIC";
        private String musicTrackId;
        private String musicTitle;
        private String musicArtist;
        private String musicAlbumArt;
        private String musicPreviewUrl;
        private Integer musicDuration;
        private String backgroundGradient;
        private Integer expiresInHours = 24;

        public Builder message(String message) {
            this.message = message;
            return this;
        }

        public Builder mediaUrl(String mediaUrl) {
            this.mediaUrl = mediaUrl;
            return this;
        }

        public Builder mediaType(String mediaType) {
            this.mediaType = mediaType;
            return this;
        }

        public Builder privacy(String privacy) {
            this.privacy = privacy;
            return this;
        }

        public Builder musicTrackId(String musicTrackId) {
            this.musicTrackId = musicTrackId;
            return this;
        }

        public Builder musicTitle(String musicTitle) {
            this.musicTitle = musicTitle;
            return this;
        }

        public Builder musicArtist(String musicArtist) {
            this.musicArtist = musicArtist;
            return this;
        }

        public Builder musicAlbumArt(String musicAlbumArt) {
            this.musicAlbumArt = musicAlbumArt;
            return this;
        }

        public Builder musicPreviewUrl(String musicPreviewUrl) {
            this.musicPreviewUrl = musicPreviewUrl;
            return this;
        }

        public Builder musicDuration(Integer musicDuration) {
            this.musicDuration = musicDuration;
            return this;
        }

        public Builder backgroundGradient(String backgroundGradient) {
            this.backgroundGradient = backgroundGradient;
            return this;
        }

        public Builder expiresInHours(Integer expiresInHours) {
            this.expiresInHours = expiresInHours;
            return this;
        }

        public CreateStoryRequest build() {
            return new CreateStoryRequest(message, mediaUrl, mediaType, privacy, musicTrackId, musicTitle, musicArtist, musicAlbumArt,
                    musicPreviewUrl, musicDuration, backgroundGradient, expiresInHours);
        }
    }
}
