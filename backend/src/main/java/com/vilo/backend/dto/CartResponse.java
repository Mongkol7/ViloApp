package com.vilo.backend.dto;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class CartResponse {

    private List<CartItemResponse> items = new ArrayList<>();
    private int itemCount;
    private BigDecimal totalAmount;
    private BigDecimal originalTotalAmount;
    private BigDecimal totalSavings;

    public CartResponse() {}

    public CartResponse(List<CartItemResponse> items, int itemCount, BigDecimal totalAmount,
                        BigDecimal originalTotalAmount, BigDecimal totalSavings) {
        this.items = items != null ? items : new ArrayList<>();
        this.itemCount = itemCount;
        this.totalAmount = totalAmount;
        this.originalTotalAmount = originalTotalAmount;
        this.totalSavings = totalSavings;
    }

    public static Builder builder() {
        return new Builder();
    }

    public List<CartItemResponse> getItems() {
        return items;
    }

    public void setItems(List<CartItemResponse> items) {
        this.items = items;
    }

    public int getItemCount() {
        return itemCount;
    }

    public void setItemCount(int itemCount) {
        this.itemCount = itemCount;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }

    public BigDecimal getOriginalTotalAmount() {
        return originalTotalAmount;
    }

    public void setOriginalTotalAmount(BigDecimal originalTotalAmount) {
        this.originalTotalAmount = originalTotalAmount;
    }

    public BigDecimal getTotalSavings() {
        return totalSavings;
    }

    public void setTotalSavings(BigDecimal totalSavings) {
        this.totalSavings = totalSavings;
    }

    public static class Builder {
        private List<CartItemResponse> items = new ArrayList<>();
        private int itemCount;
        private BigDecimal totalAmount;
        private BigDecimal originalTotalAmount;
        private BigDecimal totalSavings;

        public Builder items(List<CartItemResponse> items) {
            this.items = items;
            return this;
        }

        public Builder itemCount(int itemCount) {
            this.itemCount = itemCount;
            return this;
        }

        public Builder totalAmount(BigDecimal totalAmount) {
            this.totalAmount = totalAmount;
            return this;
        }

        public Builder originalTotalAmount(BigDecimal originalTotalAmount) {
            this.originalTotalAmount = originalTotalAmount;
            return this;
        }

        public Builder totalSavings(BigDecimal totalSavings) {
            this.totalSavings = totalSavings;
            return this;
        }

        public CartResponse build() {
            return new CartResponse(items, itemCount, totalAmount, originalTotalAmount, totalSavings);
        }
    }
}
