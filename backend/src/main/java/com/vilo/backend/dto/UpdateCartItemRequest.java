package com.vilo.backend.dto;

import jakarta.validation.constraints.NotNull;

public class UpdateCartItemRequest {

    @NotNull(message = "Quantity is required")
    private Integer quantity;

    public UpdateCartItemRequest() {}

    public UpdateCartItemRequest(Integer quantity) {
        this.quantity = quantity;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }
}
