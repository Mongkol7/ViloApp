package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.CheckoutRequest;
import com.vilo.backend.dto.DirectOrderRequest;
import com.vilo.backend.dto.OrderResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.OrderService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @PostMapping("/checkout")
    public ResponseEntity<ApiResponse<OrderResponse>> checkout(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody CheckoutRequest request
    ) {
        OrderResponse order = orderService.checkout(currentUser, request);
        return ResponseEntity.ok(ApiResponse.ok("Order placed successfully", order));
    }

    @PostMapping("/direct")
    public ResponseEntity<ApiResponse<OrderResponse>> createDirectOrder(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody DirectOrderRequest request
    ) {
        OrderResponse order = orderService.createDirectOrder(currentUser, request);
        return ResponseEntity.status(201).body(ApiResponse.ok("Order created successfully", order));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getOrderHistory(
            @AuthenticationPrincipal User currentUser
    ) {
        List<OrderResponse> orders = orderService.getOrderHistory(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Order history retrieved", orders));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrderById(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long id
    ) {
        OrderResponse order = orderService.getOrderById(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Order details retrieved", order));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<OrderResponse>> cancelOrder(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long id
    ) {
        OrderResponse order = orderService.cancelOrder(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Order cancelled successfully", order));
    }

    @PostMapping("/cancel-by-number")
    public ResponseEntity<ApiResponse<OrderResponse>> cancelOrderByNumber(
            @AuthenticationPrincipal User currentUser,
            @RequestParam String orderNumber
    ) {
        OrderResponse order = orderService.cancelOrderByNumber(currentUser, orderNumber);
        return ResponseEntity.ok(ApiResponse.ok("Order cancelled successfully", order));
    }
}
