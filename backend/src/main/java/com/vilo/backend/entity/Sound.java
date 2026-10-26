package com.vilo.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sounds", indexes = {
        @Index(name = "idx_sounds_title", columnList = "title"),
        @Index(name = "idx_sounds_artist", columnList = "artist"),
        @Index(name = "idx_sounds_usage", columnList = "usage_count DESC")
})
public class Sound {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String artist;

    @Column(name = "creator_id")
    private Long creatorId;

    @Column(name = "creator_username")
    private String creatorUsername;

    @Column(name = "audio_url", length = 1000)
    private String audioUrl;

    @Column(name = "cover_url", length = 1000)
    private String coverUrl;

    @Column(name = "album_art_url", length = 1000)
    private String albumArtUrl;

    @Column(name = "duration_seconds")
    private Integer durationSeconds = 30;

    @Column(name = "usage_count")
    private Long usageCount = 0L;

    @Column(name = "is_trending")
    private Boolean isTrending = false;

    @Column(name = "waveform_data", columnDefinition = "TEXT")
    private String waveformData;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Sound() {}

    public Sound(String title, String artist, String audioUrl, String albumArtUrl, Integer durationSeconds, Long usageCount, Boolean isTrending) {
        this.title = title;
        this.artist = artist;
        this.audioUrl = audioUrl;
        this.albumArtUrl = albumArtUrl;
        this.coverUrl = albumArtUrl;
        this.durationSeconds = durationSeconds;
        this.usageCount = usageCount;
        this.isTrending = isTrending;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public Sound(String title, Long creatorId, String creatorUsername, String audioUrl, String coverUrl, Long usageCount) {
        this.title = title;
        this.creatorId = creatorId;
        this.creatorUsername = creatorUsername;
        this.artist = creatorUsername != null ? "@" + creatorUsername : "Original Sound";
        this.audioUrl = audioUrl;
        this.coverUrl = coverUrl;
        this.albumArtUrl = coverUrl;
        this.usageCount = usageCount != null ? usageCount : 0L;
        this.durationSeconds = 30;
        this.isTrending = false;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (usageCount == null) usageCount = 0L;
        if (isTrending == null) isTrending = false;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getArtist() {
        return artist;
    }

    public void setArtist(String artist) {
        this.artist = artist;
    }

    public String getAudioUrl() {
        return audioUrl;
    }

    public void setAudioUrl(String audioUrl) {
        this.audioUrl = audioUrl;
    }

    public String getAlbumArtUrl() {
        return albumArtUrl;
    }

    public void setAlbumArtUrl(String albumArtUrl) {
        this.albumArtUrl = albumArtUrl;
    }

    public Integer getDurationSeconds() {
        return durationSeconds;
    }

    public void setDurationSeconds(Integer durationSeconds) {
        this.durationSeconds = durationSeconds;
    }

    public Long getUsageCount() {
        return usageCount;
    }

    public void setUsageCount(Long usageCount) {
        this.usageCount = usageCount;
    }

    public Boolean getIsTrending() {
        return isTrending;
    }

    public void setIsTrending(Boolean trending) {
        isTrending = trending;
    }

    public String getWaveformData() {
        return waveformData;
    }

    public void setWaveformData(String waveformData) {
        this.waveformData = waveformData;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Long getCreatorId() {
        return creatorId;
    }

    public void setCreatorId(Long creatorId) {
        this.creatorId = creatorId;
    }

    public String getCreatorUsername() {
        return creatorUsername != null ? creatorUsername : artist;
    }

    public void setCreatorUsername(String creatorUsername) {
        this.creatorUsername = creatorUsername;
    }

    public String getCoverUrl() {
        return coverUrl != null && !coverUrl.isEmpty() ? coverUrl : albumArtUrl;
    }

    public void setCoverUrl(String coverUrl) {
        this.coverUrl = coverUrl;
        if (this.albumArtUrl == null || this.albumArtUrl.isEmpty()) {
            this.albumArtUrl = coverUrl;
        }
    }
}
