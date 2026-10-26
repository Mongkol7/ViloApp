package com.vilo.backend.dto;

import com.vilo.backend.entity.OrderItem;

import java.math.BigDecimal;

public class OrderItemResponse {

    private Long id;
    private Long productId;
    private String productTitle;
    private String productImageUrl;
    private BigDecimal price;
    private Integer quantity;
    private BigDecimal subtotal;
    private String variant;

    public OrderItemResponse() {}

    public OrderItemResponse(Long id, Long productId, String productTitle, String productImageUrl,
                             BigDecimal price, Integer quantity, BigDecimal subtotal, String variant) {
        this.id = id;
        this.productId = productId;
        this.productTitle = productTitle;
        this.productImageUrl = productImageUrl;
        this.price = price;
        this.quantity = quantity;
        this.subtotal = subtotal;
        this.variant = variant;
    }

    public static OrderItemResponse fromEntity(OrderItem item) {
        if (item == null) return null;
        BigDecimal subtotal = item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
        Long prodId = item.getProduct() != null ? item.getProduct().getId() : null;

        return OrderItemResponse.builder()
                .id(item.getId())
                .productId(prodId)
                .productTitle(item.getProductTitle())
                .productImageUrl(item.getProductImageUrl())
                .price(item.getPrice())
                .quantity(item.getQuantity())
                .subtotal(subtotal)
                .variant(item.getVariant())
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

    public String getProductImageUrl() {
        return productImageUrl;
    }

    public void setProductImageUrl(String productImageUrl) {
        this.productImageUrl = productImageUrl;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
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

    public String getVariant() {
        return variant;
    }

    public void setVariant(String variant) {
        this.variant = variant;
    }

    public static class Builder {
        private Long id;
        private Long productId;
        private String productTitle;
        private String productImageUrl;
        private BigDecimal price;
        private Integer quantity;
        private BigDecimal subtotal;
        private String variant;

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

        public Builder productImageUrl(String productImageUrl) {
            this.productImageUrl = productImageUrl;
            return this;
        }

        public Builder price(BigDecimal price) {
            this.price = price;
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

        public Builder variant(String variant) {
            this.variant = variant;
            return this;
        }

        public OrderItemResponse build() {
            return new OrderItemResponse(id, productId, productTitle, productImageUrl, price, quantity, subtotal, variant);
        }
    }
}
