package com.vilo.backend.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public class DirectOrderItemRequest {
    @NotNull
    private Long productId;
    @NotNull
    @Min(1)
    private Integer quantity;
    private String variant;

    public DirectOrderItemRequest() {}

    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public String getVariant() { return variant; }
    public void setVariant(String variant) { this.variant = variant; }
}
