package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.AddToCartRequest;
import com.vilo.backend.dto.CartItemResponse;
import com.vilo.backend.dto.CartResponse;
import com.vilo.backend.dto.UpdateCartItemRequest;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.CartService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/cart")
public class CartController {

    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<CartResponse>> getCart(@AuthenticationPrincipal User currentUser) {
        CartResponse cart = cartService.getCart(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Cart retrieved successfully", cart));
    }

    @PostMapping("/items")
    public ResponseEntity<ApiResponse<CartItemResponse>> addToCart(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody AddToCartRequest request
    ) {
        CartItemResponse item = cartService.addToCart(currentUser, request);
        return ResponseEntity.ok(ApiResponse.ok("Item added to cart", item));
    }

    @PutMapping("/items/{itemId}")
    public ResponseEntity<ApiResponse<CartItemResponse>> updateItemQuantity(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long itemId,
            @Valid @RequestBody UpdateCartItemRequest request
    ) {
        CartItemResponse item = cartService.updateQuantity(currentUser, itemId, request.getQuantity());
        String msg = (item == null) ? "Item removed from cart" : "Cart item updated";
        return ResponseEntity.ok(ApiResponse.ok(msg, item));
    }

    @DeleteMapping("/items/{itemId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> removeItem(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long itemId
    ) {
        cartService.removeItem(currentUser, itemId);
        return ResponseEntity.ok(ApiResponse.ok("Item removed from cart", Map.of("removedItemId", itemId)));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Map<String, String>>> clearCart(@AuthenticationPrincipal User currentUser) {
        cartService.clearCart(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Cart cleared successfully", Map.of("status", "cleared")));
    }
}
