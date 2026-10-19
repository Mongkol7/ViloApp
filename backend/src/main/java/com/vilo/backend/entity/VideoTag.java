package com.vilo.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "video_tags")
public class VideoTag {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "video_id", nullable = false)
    private Video video;

    @Column(name = "tag_name", nullable = false, length = 50)
    private String tagName;

    public VideoTag() {}

    public VideoTag(Video video, String tagName) {
        this.video = video;
        this.tagName = tagName;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Video getVideo() { return video; }
    public void setVideo(Video video) { this.video = video; }

    public String getTagName() { return tagName; }
    public void setTagName(String tagName) { this.tagName = tagName; }
}