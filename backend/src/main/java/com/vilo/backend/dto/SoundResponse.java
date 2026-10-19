package com.vilo.backend.dto;

import com.vilo.backend.entity.Sound;

import java.time.LocalDateTime;

public class SoundResponse {
    private Long id;
    private String title;
    private String artist;
    private Long creatorId;
    private String creatorUsername;
    private String audioUrl;
    private String coverUrl;
    private String albumArtUrl;
    private Integer durationSeconds;
    private Long usageCount;
    private String formattedUsageCount;
    private String usedByLabel;
    private Boolean isTrending;
    private String waveformData;
    private LocalDateTime createdAt;

    public SoundResponse() {}

    public static SoundResponse fromEntity(Sound sound) {
        SoundResponse dto = new SoundResponse();
        dto.setId(sound.getId());
        dto.setTitle(sound.getTitle());
        dto.setArtist(sound.getArtist());
        dto.setCreatorId(sound.getCreatorId());
        dto.setCreatorUsername(sound.getCreatorUsername());
        dto.setAudioUrl(sound.getAudioUrl());
        dto.setCoverUrl(sound.getCoverUrl());
        dto.setAlbumArtUrl(sound.getAlbumArtUrl());
        dto.setDurationSeconds(sound.getDurationSeconds());
        dto.setUsageCount(sound.getUsageCount());
        dto.setIsTrending(sound.getIsTrending());
        dto.setWaveformData(sound.getWaveformData());
        dto.setCreatedAt(sound.getCreatedAt());
        String formatted = formatCount(sound.getUsageCount());
        dto.setFormattedUsageCount(formatted);
        dto.setUsedByLabel(formatted);
        return dto;
    }

    private static String formatCount(Long count) {
        if (count == null || count <= 0) return "0 videos";
        if (count >= 1_000_000) {
            return String.format("%.1fM", count / 1_000_000.0);
        } else if (count >= 1_000) {
            return String.format("%.1fK", count / 1_000.0);
        }
        return count + " videos";
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

    public String getAudioUrl() {
        return audioUrl;
    }

    public void setAudioUrl(String audioUrl) {
        this.audioUrl = audioUrl;
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

    public String getAlbumArtUrl() {
        return albumArtUrl != null && !albumArtUrl.isEmpty() ? albumArtUrl : coverUrl;
    }

    public void setAlbumArtUrl(String albumArtUrl) {
        this.albumArtUrl = albumArtUrl;
        if (this.coverUrl == null || this.coverUrl.isEmpty()) {
            this.coverUrl = albumArtUrl;
        }
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

    public String getFormattedUsageCount() {
        return formattedUsageCount;
    }

    public void setFormattedUsageCount(String formattedUsageCount) {
        this.formattedUsageCount = formattedUsageCount;
    }

    public String getUsedByLabel() {
        return usedByLabel != null ? usedByLabel : formattedUsageCount;
    }

    public void setUsedByLabel(String usedByLabel) {
        this.usedByLabel = usedByLabel;
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
}
