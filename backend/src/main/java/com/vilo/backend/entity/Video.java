package com.vilo.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "videos", indexes = {
    @Index(name = "idx_creator_created", columnList = "creator_id, created_at")
})
public class Video {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "creator_id", nullable = false)
    private User creator;

    @Column(length = 255)
    private String title;

    @Column(length = 2000)
    private String description;

    @Column(nullable = false, length = 500)
    private String caption;

    @Column(name = "video_url", nullable = false, length = 4000)
    private String videoUrl;

    @Column(name = "thumbnail_url", length = 1000)
    private String thumbnailUrl;

    @Column(name = "image_urls", columnDefinition = "TEXT")
    private String imageUrls;

    @Column(name = "sound_id")
    private Long soundId;

    @Column(name = "music_title")
    private String musicTitle;

    @Column(name = "music_artist")
    private String musicArtist;

    @Column(name = "audio_url", length = 1000)
    private String audioUrl;

    @Column(name = "views_count")
    private Long viewCount = 0L;

    @Column(name = "likes_count")
    private Long likeCount = 0L;

    @Column(name = "comments_count")
    private Long commentCount = 0L;

    @Column(name = "saves_count")
    private Long saveCount = 0L;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "video", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<VideoTag> tags = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.updatedAt == null) {
            this.updatedAt = LocalDateTime.now();
        }
        if (this.viewCount == null) this.viewCount = 0L;
        if (this.likeCount == null) this.likeCount = 0L;
        if (this.commentCount == null) this.commentCount = 0L;
        if (this.saveCount == null) this.saveCount = 0L;

        if ((this.caption == null || this.caption.isBlank()) && (this.title != null || this.description != null)) {
            this.caption = (this.title != null ? this.title : "") + 
                    (this.description != null && !this.description.isBlank() ? " " + this.description : "");
        }
        if (this.title == null && this.caption != null) {
            this.title = this.caption.length() > 100 ? this.caption.substring(0, 100) : this.caption;
        }
        if (this.description == null && this.caption != null) {
            this.description = this.caption;
        }
        if (this.musicTitle == null || this.musicTitle.isBlank()) {
            String creatorHandle = (this.creator != null && this.creator.getUsername() != null)
                    ? this.creator.getUsername().replace("@", "")
                    : "creator";
            this.musicTitle = "Original Sound - @" + creatorHandle;
        }
        if (this.musicArtist == null || this.musicArtist.isBlank()) {
            String creatorHandle = (this.creator != null && this.creator.getUsername() != null)
                    ? this.creator.getUsername()
                    : "@creator";
            this.musicArtist = creatorHandle.startsWith("@") ? creatorHandle : "@" + creatorHandle;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public Video() {}

    public Video(User creator, String videoUrl, String thumbnailUrl, String caption,
                 String musicTitle, Long likesCount, Long commentsCount, Long savesCount) {
        this.creator = creator;
        this.videoUrl = videoUrl;
        this.thumbnailUrl = thumbnailUrl;
        this.caption = caption;
        this.title = caption != null && caption.length() > 100 ? caption.substring(0, 100) : caption;
        this.description = caption;
        this.musicTitle = musicTitle != null ? musicTitle : "Original Sound";
        this.likeCount = likesCount != null ? likesCount : 0L;
        this.commentCount = commentsCount != null ? commentsCount : 0L;
        this.saveCount = savesCount != null ? savesCount : 0L;
        this.viewCount = (this.likeCount * 3) + 1000L;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public Video(User creator, String title, String description, String caption, String videoUrl, String thumbnailUrl) {
        this.creator = creator;
        this.title = title;
        this.description = description;
        this.caption = caption != null && !caption.isBlank() ? caption : (title != null ? title : "");
        this.videoUrl = videoUrl;
        this.thumbnailUrl = thumbnailUrl;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getCreator() { return creator; }
    public void setCreator(User creator) { this.creator = creator; }

    public Long getCreatorId() {
        return creator != null ? creator.getId() : null;
    }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getCaption() { return caption; }
    public void setCaption(String caption) { this.caption = caption; }

    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }

    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }

    public String getMusicTitle() { return musicTitle; }
    public void setMusicTitle(String musicTitle) { this.musicTitle = musicTitle; }

    public String getMusicName() { return musicTitle; }
    public void setMusicName(String musicName) { this.musicTitle = musicName; }

    public String getMusicArtist() { return musicArtist; }
    public void setMusicArtist(String musicArtist) { this.musicArtist = musicArtist; }

    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }

    public Long getViewCount() { return viewCount; }
    public void setViewCount(Long viewCount) { this.viewCount = viewCount; }

    public Long getViewsCount() { return viewCount; }
    public void setViewsCount(Long viewsCount) { this.viewCount = viewsCount; }

    public Long getLikeCount() { return likeCount; }
    public void setLikeCount(Long likeCount) { this.likeCount = likeCount; }

    public Long getLikesCount() { return likeCount; }
    public void setLikesCount(Long likesCount) { this.likeCount = likesCount; }

    public Long getCommentCount() { return commentCount; }
    public void setCommentCount(Long commentCount) { this.commentCount = commentCount; }

    public Long getCommentsCount() { return commentCount; }
    public void setCommentsCount(Long commentsCount) { this.commentCount = commentsCount; }

    public Long getSaveCount() { return saveCount; }
    public void setSaveCount(Long saveCount) { this.saveCount = saveCount; }

    public Long getSavesCount() { return saveCount; }
    public void setSavesCount(Long savesCount) { this.saveCount = savesCount; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public Long getSoundId() { return soundId; }
    public void setSoundId(Long soundId) { this.soundId = soundId; }

    public List<VideoTag> getTags() { return tags; }
    public void setTags(List<VideoTag> tags) { this.tags = tags; }

    public String getImageUrls() { return imageUrls; }
    public void setImageUrls(String imageUrls) { this.imageUrls = imageUrls; }
}
