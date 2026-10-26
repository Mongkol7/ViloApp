package com.vilo.backend.dto;

import com.vilo.backend.entity.Product;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class ProductResponse {

    private Long id;
    private String title;
    private String description;
    private BigDecimal price;
    private BigDecimal originalPrice;
    private Integer discountPercentage;
    private Integer stock;
    private Double rating;
    private Integer reviewCount;
    private Integer salesCount;
    private CategoryResponse category;
    private UserResponse seller;
    private List<String> images;
    private Set<Long> videoIds;
    private Instant createdAt;

    public ProductResponse() {}

    public ProductResponse(Long id, String title, String description, BigDecimal price, BigDecimal originalPrice,
                           Integer discountPercentage, Integer stock, Double rating, Integer reviewCount,
                           Integer salesCount, CategoryResponse category, UserResponse seller,
                           List<String> images, Set<Long> videoIds, Instant createdAt) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.price = price;
        this.originalPrice = originalPrice;
        this.discountPercentage = discountPercentage;
        this.stock = stock;
        this.rating = rating;
        this.reviewCount = reviewCount;
        this.salesCount = salesCount;
        this.category = category;
        this.seller = seller;
        this.images = images != null ? images : new ArrayList<>();
        this.videoIds = videoIds != null ? videoIds : new HashSet<>();
        this.createdAt = createdAt;
    }

    public static ProductResponse fromEntity(Product product) {
        if (product == null) return null;

        Integer discount = null;
        if (product.getOriginalPrice() != null && product.getOriginalPrice().compareTo(BigDecimal.ZERO) > 0
                && product.getPrice() != null && product.getOriginalPrice().compareTo(product.getPrice()) > 0) {
            BigDecimal diff = product.getOriginalPrice().subtract(product.getPrice());
            discount = diff.multiply(BigDecimal.valueOf(100))
                    .divide(product.getOriginalPrice(), 0, RoundingMode.HALF_UP)
                    .intValue();
        }

        return ProductResponse.builder()
                .id(product.getId())
                .title(product.getTitle())
                .description(product.getDescription())
                .price(product.getPrice())
                .originalPrice(product.getOriginalPrice())
                .discountPercentage(discount)
                .stock(product.getStock())
                .rating(product.getRating())
                .reviewCount(product.getReviewCount())
                .salesCount(product.getSalesCount())
                .category(CategoryResponse.fromEntity(product.getCategory()))
                .seller(UserResponse.fromEntity(product.getSeller()))
                .images(product.getImages())
                .videoIds(product.getVideoIds())
                .createdAt(product.getCreatedAt())
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

    public Integer getDiscountPercentage() {
        return discountPercentage;
    }

    public void setDiscountPercentage(Integer discountPercentage) {
        this.discountPercentage = discountPercentage;
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

    public CategoryResponse getCategory() {
        return category;
    }

    public void setCategory(CategoryResponse category) {
        this.category = category;
    }

    public UserResponse getSeller() {
        return seller;
    }

    public void setSeller(UserResponse seller) {
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

    public static class Builder {
        private Long id;
        private String title;
        private String description;
        private BigDecimal price;
        private BigDecimal originalPrice;
        private Integer discountPercentage;
        private Integer stock;
        private Double rating;
        private Integer reviewCount;
        private Integer salesCount;
        private CategoryResponse category;
        private UserResponse seller;
        private List<String> images = new ArrayList<>();
        private Set<Long> videoIds = new HashSet<>();
        private Instant createdAt;

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

        public Builder discountPercentage(Integer discountPercentage) {
            this.discountPercentage = discountPercentage;
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

        public Builder category(CategoryResponse category) {
            this.category = category;
            return this;
        }

        public Builder seller(UserResponse seller) {
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

        public ProductResponse build() {
            return new ProductResponse(id, title, description, price, originalPrice, discountPercentage,
                    stock, rating, reviewCount, salesCount, category, seller, images, videoIds, createdAt);
        }
    }
}
