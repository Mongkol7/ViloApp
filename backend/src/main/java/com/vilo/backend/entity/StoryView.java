package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(
        name = "story_views",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_story_viewer",
                        columnNames = {"story_id", "viewer_id"}
                )
        }
)
public class StoryView {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "story_id", nullable = false)
    private ThoughtStory story;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "viewer_id", nullable = false)
    private User viewer;

    @CreationTimestamp
    @Column(name = "viewed_at", updatable = false)
    private Instant viewedAt;

    public StoryView() {
    }

    public StoryView(Long id, ThoughtStory story, User viewer, Instant viewedAt) {
        this.id = id;
        this.story = story;
        this.viewer = viewer;
        this.viewedAt = viewedAt;
    }

    public static Builder builder() {
        return new Builder();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public ThoughtStory getStory() {
        return story;
    }

    public void setStory(ThoughtStory story) {
        this.story = story;
    }

    public User getViewer() {
        return viewer;
    }

    public void setViewer(User viewer) {
        this.viewer = viewer;
    }

    public Instant getViewedAt() {
        return viewedAt;
    }

    public void setViewedAt(Instant viewedAt) {
        this.viewedAt = viewedAt;
    }

    public static class Builder {
        private Long id;
        private ThoughtStory story;
        private User viewer;
        private Instant viewedAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder story(ThoughtStory story) {
            this.story = story;
            return this;
        }

        public Builder viewer(User viewer) {
            this.viewer = viewer;
            return this;
        }

        public Builder viewedAt(Instant viewedAt) {
            this.viewedAt = viewedAt;
            return this;
        }

        public StoryView build() {
            return new StoryView(id, story, viewer, viewedAt);
        }
    }
}
