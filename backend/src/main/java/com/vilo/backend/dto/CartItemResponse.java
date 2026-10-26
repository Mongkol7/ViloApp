package com.vilo.backend.dto;

import com.vilo.backend.entity.CartItem;

import java.math.BigDecimal;
import java.time.Instant;

public class CartItemResponse {

    private Long id;
    private Long productId;
    private String productTitle;
    private String productImage;
    private BigDecimal price;
    private BigDecimal originalPrice;
    private Integer quantity;
    private BigDecimal subtotal;
    private Integer stock;
    private String variant;
    private Instant createdAt;

    public CartItemResponse() {}

    public CartItemResponse(Long id, Long productId, String productTitle, String productImage,
                            BigDecimal price, BigDecimal originalPrice, Integer quantity,
                            BigDecimal subtotal, Integer stock, String variant, Instant createdAt) {
        this.id = id;
        this.productId = productId;
        this.productTitle = productTitle;
        this.productImage = productImage;
        this.price = price;
        this.originalPrice = originalPrice;
        this.quantity = quantity;
        this.subtotal = subtotal;
        this.stock = stock;
        this.variant = variant;
        this.createdAt = createdAt;
    }

    public static CartItemResponse fromEntity(CartItem item) {
        if (item == null) return null;
        var p = item.getProduct();
        BigDecimal price = p.getPrice();
        BigDecimal subtotal = price.multiply(BigDecimal.valueOf(item.getQuantity()));
        String firstImage = (p.getImages() != null && !p.getImages().isEmpty()) ? p.getImages().get(0) : "";

        return CartItemResponse.builder()
                .id(item.getId())
                .productId(p.getId())
                .productTitle(p.getTitle())
                .productImage(firstImage)
                .price(price)
                .originalPrice(p.getOriginalPrice())
                .quantity(item.getQuantity())
                .subtotal(subtotal)
                .stock(p.getStock())
                .variant(item.getVariant())
                .createdAt(item.getCreatedAt())
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

    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public String getProductTitle() {
        return productTitle;
    }

    public void setProductTitle(String productTitle) {
        this.productTitle = productTitle;
    }

    public String getProductImage() {
        return productImage;
    }

    public void setProductImage(String productImage) {
        this.productImage = productImage;
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

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getSubtotal() {
        return subtotal;
    }

    public void setSubtotal(BigDecimal subtotal) {
        this.subtotal = subtotal;
    }

    public Integer getStock() {
        return stock;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }

    public String getVariant() {
        return variant;
    }

    public void setVariant(String variant) {
        this.variant = variant;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public static class Builder {
        private Long id;
        private Long productId;
        private String productTitle;
        private String productImage;
        private BigDecimal price;
        private BigDecimal originalPrice;
        private Integer quantity;
        private BigDecimal subtotal;
        private Integer stock;
        private String variant;
        private Instant createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder productId(Long productId) {
            this.productId = productId;
            return this;
        }

        public Builder productTitle(String productTitle) {
            this.productTitle = productTitle;
            return this;
        }

        public Builder productImage(String productImage) {
            this.productImage = productImage;
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

        public Builder quantity(Integer quantity) {
            this.quantity = quantity;
            return this;
        }

        public Builder subtotal(BigDecimal subtotal) {
            this.subtotal = subtotal;
            return this;
        }

        public Builder stock(Integer stock) {
            this.stock = stock;
            return this;
        }

        public Builder variant(String variant) {
            this.variant = variant;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public CartItemResponse build() {
            return new CartItemResponse(id, productId, productTitle, productImage, price, originalPrice,
                    quantity, subtotal, stock, variant, createdAt);
        }
    }
}
