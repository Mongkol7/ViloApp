package com.vilo.backend.entity;

/**
 * Type-alias / subclass of Sound representing a track in the sounds table.
 */
public class SoundTrack extends Sound {
    public SoundTrack() {
        super();
    }

    public SoundTrack(String title, Long creatorId, String creatorUsername, String audioUrl, String coverUrl, Long usageCount) {
        super(title, creatorId, creatorUsername, audioUrl, coverUrl, usageCount);
    }
}
