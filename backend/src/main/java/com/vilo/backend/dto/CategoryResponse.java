package com.vilo.backend.dto;

import com.vilo.backend.entity.Category;

import java.time.Instant;

public class CategoryResponse {

    private Long id;
    private String name;
    private String slug;
    private String iconUrl;
    private String imageUrl;
    private Instant createdAt;

    public CategoryResponse() {}

    public CategoryResponse(Long id, String name, String slug, String iconUrl, String imageUrl, Instant createdAt) {
        this.id = id;
        this.name = name;
        this.slug = slug;
        this.iconUrl = iconUrl;
        this.imageUrl = imageUrl;
        this.createdAt = createdAt;
    }

    public static CategoryResponse fromEntity(Category category) {
        if (category == null) return null;
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .slug(category.getSlug())
                .iconUrl(category.getIconUrl())
                .imageUrl(category.getImageUrl())
                .createdAt(category.getCreatedAt())
                .build();
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSlug() {
        return slug;
    }

    public void setSlug(String slug) {
        this.slug = slug;
    }

    public String getIconUrl() {
        return iconUrl;
    }

    public void setIconUrl(String iconUrl) {
        this.iconUrl = iconUrl;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public static class Builder {
        private Long id;
        private String name;
        private String slug;
        private String iconUrl;
        private String imageUrl;
        private Instant createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder name(String name) {
            this.name = name;
            return this;
        }

        public Builder slug(String slug) {
            this.slug = slug;
            return this;
        }

        public Builder iconUrl(String iconUrl) {
            this.iconUrl = iconUrl;
            return this;
        }

        public Builder imageUrl(String imageUrl) {
            this.imageUrl = imageUrl;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public CategoryResponse build() {
            return new CategoryResponse(id, name, slug, iconUrl, imageUrl, createdAt);
        }
    }
}
