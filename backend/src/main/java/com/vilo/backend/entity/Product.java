package com.vilo.backend.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "products")
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "original_price", precision = 10, scale = 2)
    private BigDecimal originalPrice;

    @Column(nullable = false)
    private Integer stock = 100;

    @Column(nullable = false)
    private Double rating = 4.8;

    @Column(name = "review_count", nullable = false)
    private Integer reviewCount = 0;

    @Column(name = "sales_count", nullable = false)
    private Integer salesCount = 0;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "category_id")
    private Category category;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "seller_id")
    private User seller;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "product_images", joinColumns = @JoinColumn(name = "product_id"))
    @Column(name = "image_url", length = 500)
    private List<String> images = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "product_videos", joinColumns = @JoinColumn(name = "product_id"))
    @Column(name = "video_id")
    private Set<Long> videoIds = new HashSet<>();

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;

    public Product() {}

    public Product(Long id, String title, String description, BigDecimal price, BigDecimal originalPrice,
                   Integer stock, Double rating, Integer reviewCount, Integer salesCount,
                   Category category, User seller, List<String> images, Set<Long> videoIds,
                   Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.price = price;
        this.originalPrice = originalPrice;
        this.stock = stock;
        this.rating = rating;
        this.reviewCount = reviewCount;
        this.salesCount = salesCount;
        this.category = category;
        this.seller = seller;
        this.images = images != null ? images : new ArrayList<>();
        this.videoIds = videoIds != null ? videoIds : new HashSet<>();
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
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

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public BigDecimal getOriginalPrice() {
        return originalPrice;
    }

    public void setOriginalPrice(BigDecimal originalPrice) {
        this.originalPrice = originalPrice;
    }

    public Integer getStock() {
        return stock;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }

    public Double getRating() {
        return rating;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public Integer getReviewCount() {
        return reviewCount;
    }

    public void setReviewCount(Integer reviewCount) {
        this.reviewCount = reviewCount;
    }

    public Integer getSalesCount() {
        return salesCount;
    }

    public void setSalesCount(Integer salesCount) {
        this.salesCount = salesCount;
    }

    public Category getCategory() {
        return category;
    }

    public void setCategory(Category category) {
        this.category = category;
    }

    public User getSeller() {
        return seller;
    }

    public void setSeller(User seller) {
        this.seller = seller;
    }

    public List<String> getImages() {
        return images;
    }

    public void setImages(List<String> images) {
        this.images = images;
    }

    public Set<Long> getVideoIds() {
        return videoIds;
    }

    public void setVideoIds(Set<Long> videoIds) {
        this.videoIds = videoIds;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public static class Builder {
        private Long id;
        private String title;
        private String description;
        private BigDecimal price;
        private BigDecimal originalPrice;
        private Integer stock = 100;
        private Double rating = 4.8;
        private Integer reviewCount = 0;
        private Integer salesCount = 0;
        private Category category;
        private User seller;
        private List<String> images = new ArrayList<>();
        private Set<Long> videoIds = new HashSet<>();
        private Instant createdAt;
        private Instant updatedAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder title(String title) {
            this.title = title;
            return this;
        }

        public Builder description(String description) {
            this.description = description;
            return this;
        }

        public Builder price(BigDecimal price) {
            this.price = price;
            return this;
        }

        public Builder originalPrice(BigDecimal originalPrice) {
            this.originalPrice = originalPrice;
            return this;
        }

        public Builder stock(Integer stock) {
            this.stock = stock;
            return this;
        }

        public Builder rating(Double rating) {
            this.rating = rating;
            return this;
        }

        public Builder reviewCount(Integer reviewCount) {
            this.reviewCount = reviewCount;
            return this;
        }

        public Builder salesCount(Integer salesCount) {
            this.salesCount = salesCount;
            return this;
        }

        public Builder category(Category category) {
            this.category = category;
            return this;
        }

        public Builder seller(User seller) {
            this.seller = seller;
            return this;
        }

        public Builder images(List<String> images) {
            this.images = images;
            return this;
        }

        public Builder videoIds(Set<Long> videoIds) {
            this.videoIds = videoIds;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public Builder updatedAt(Instant updatedAt) {
            this.updatedAt = updatedAt;
            return this;
        }

        public Product build() {
            return new Product(id, title, description, price, originalPrice, stock, rating, reviewCount, salesCount,
                    category, seller, images, videoIds, createdAt, updatedAt);
        }
    }
}
