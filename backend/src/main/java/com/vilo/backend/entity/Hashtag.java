package com.vilo.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "hashtags", indexes = {
        @Index(name = "idx_hashtags_tag", columnList = "tag", unique = true),
        @Index(name = "idx_hashtags_usage", columnList = "usage_count DESC")
})
public class Hashtag {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String tag;

    @Column(name = "usage_count")
    private Long usageCount = 0L;

    @Column(name = "is_trending")
    private Boolean isTrending = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Hashtag() {}

    public Hashtag(String tag, Long usageCount, Boolean isTrending) {
        this.tag = tag.toLowerCase().replaceAll("^#", "");
        this.usageCount = usageCount;
        this.isTrending = isTrending;
        this.createdAt = LocalDateTime.now();
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (usageCount == null) usageCount = 0L;
        if (isTrending == null) isTrending = false;
        if (tag != null) tag = tag.toLowerCase().replaceAll("^#", "");
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag != null ? tag.toLowerCase().replaceAll("^#", "") : null;
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

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
