package com.vilo.backend.dto;

import com.vilo.backend.entity.Sound;

public class SoundResponse {
    private Long id;
    private String title;
    private String artist;
    private String audioUrl;
    private String albumArtUrl;
    private Integer durationSeconds;
    private Long usageCount;
    private String formattedUsageCount;
    private Boolean isTrending;
    private String waveformData;

    public SoundResponse() {}

    public static SoundResponse fromEntity(Sound sound) {
        SoundResponse dto = new SoundResponse();
        dto.setId(sound.getId());
        dto.setTitle(sound.getTitle());
        dto.setArtist(sound.getArtist());
        dto.setAudioUrl(sound.getAudioUrl());
        dto.setAlbumArtUrl(sound.getAlbumArtUrl());
        dto.setDurationSeconds(sound.getDurationSeconds());
        dto.setUsageCount(sound.getUsageCount());
        dto.setIsTrending(sound.getIsTrending());
        dto.setWaveformData(sound.getWaveformData());
        dto.setFormattedUsageCount(formatCount(sound.getUsageCount()));
        return dto;
    }

    private static String formatCount(Long count) {
        if (count == null || count <= 0) return "0 videos";
        if (count >= 1_000_000) {
            return String.format("%.1fM videos", count / 1_000_000.0);
        } else if (count >= 1_000) {
            return String.format("%.1fK videos", count / 1_000.0);
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

    public String getFormattedUsageCount() {
        return formattedUsageCount;
    }

    public void setFormattedUsageCount(String formattedUsageCount) {
        this.formattedUsageCount = formattedUsageCount;
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
}
