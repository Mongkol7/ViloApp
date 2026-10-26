package com.vilo.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(name = "order_items")
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Column(name = "product_title", nullable = false, length = 200)
    private String productTitle;

    @Column(name = "product_image_url", length = 500)
    private String productImageUrl;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(nullable = false)
    private Integer quantity;

    @Column(length = 100)
    private String variant;

    public OrderItem() {}

    public OrderItem(Long id, Order order, Product product, String productTitle, String productImageUrl,
                     BigDecimal price, Integer quantity, String variant) {
        this.id = id;
        this.order = order;
        this.product = product;
        this.productTitle = productTitle;
        this.productImageUrl = productImageUrl;
        this.price = price;
        this.quantity = quantity;
        this.variant = variant;
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

    public Order getOrder() {
        return order;
    }

    public void setOrder(Order order) {
        this.order = order;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
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

    public String getVariant() {
        return variant;
    }

    public void setVariant(String variant) {
        this.variant = variant;
    }

    public static class Builder {
        private Long id;
        private Order order;
        private Product product;
        private String productTitle;
        private String productImageUrl;
        private BigDecimal price;
        private Integer quantity;
        private String variant;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder order(Order order) {
            this.order = order;
            return this;
        }

        public Builder product(Product product) {
            this.product = product;
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

        public Builder variant(String variant) {
            this.variant = variant;
            return this;
        }

        public OrderItem build() {
            return new OrderItem(id, order, product, productTitle, productImageUrl, price, quantity, variant);
        }
    }
}
