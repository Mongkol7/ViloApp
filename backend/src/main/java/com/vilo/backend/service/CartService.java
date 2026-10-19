package com.vilo.backend.service;

import com.vilo.backend.dto.AddToCartRequest;
import com.vilo.backend.dto.CartItemResponse;
import com.vilo.backend.dto.CartResponse;
import com.vilo.backend.entity.CartItem;
import com.vilo.backend.entity.Product;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.CartItemRepository;
import com.vilo.backend.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class CartService {

    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;

    public CartService(CartItemRepository cartItemRepository, ProductRepository productRepository) {
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
    }

    @Transactional(readOnly = true)
    public CartResponse getCart(User user) {
        List<CartItem> items = cartItemRepository.findByUserOrderByCreatedAtDesc(user);
        List<CartItemResponse> itemResponses = items.stream()
                .map(CartItemResponse::fromEntity)
                .collect(Collectors.toList());

        BigDecimal total = BigDecimal.ZERO;
        BigDecimal originalTotal = BigDecimal.ZERO;
        int totalCount = 0;

        for (CartItem item : items) {
            BigDecimal price = item.getProduct().getPrice();
            BigDecimal origPrice = item.getProduct().getOriginalPrice() != null
                    ? item.getProduct().getOriginalPrice()
                    : price;

            BigDecimal qty = BigDecimal.valueOf(item.getQuantity());
            total = total.add(price.multiply(qty));
            originalTotal = originalTotal.add(origPrice.multiply(qty));
            totalCount += item.getQuantity();
        }

        BigDecimal savings = originalTotal.compareTo(total) > 0 ? originalTotal.subtract(total) : BigDecimal.ZERO;

        return CartResponse.builder()
                .items(itemResponses)
                .itemCount(totalCount)
                .totalAmount(total)
                .originalTotalAmount(originalTotal)
                .totalSavings(savings)
                .build();
    }

    public CartItemResponse addToCart(User user, AddToCartRequest request) {
        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + request.getProductId()));

        if (product.getStock() < request.getQuantity()) {
            throw new BadRequestException("Requested quantity exceeds available stock (" + product.getStock() + ")");
        }

        Optional<CartItem> existingItemOpt = cartItemRepository.findByUserAndProduct(user, product);
        CartItem cartItem;

        if (existingItemOpt.isPresent()) {
            cartItem = existingItemOpt.get();
            int newQuantity = cartItem.getQuantity() + request.getQuantity();
            if (newQuantity > product.getStock()) {
                throw new BadRequestException("Cannot add more. Exceeds total available stock (" + product.getStock() + ")");
            }
            cartItem.setQuantity(newQuantity);
            if (request.getVariant() != null && !request.getVariant().isBlank()) {
                cartItem.setVariant(request.getVariant());
            }
        } else {
            cartItem = CartItem.builder()
                    .user(user)
                    .product(product)
                    .quantity(request.getQuantity())
                    .variant(request.getVariant())
                    .build();
        }

        CartItem saved = cartItemRepository.save(cartItem);
        return CartItemResponse.fromEntity(saved);
    }

    public CartItemResponse updateQuantity(User user, Long itemId, Integer quantity) {
        CartItem item = cartItemRepository.findByIdAndUser(itemId, user)
                .orElseThrow(() -> new ResourceNotFoundException("Cart item not found with id: " + itemId));

        if (quantity == null || quantity <= 0) {
            cartItemRepository.delete(item);
            return null;
        }

        if (quantity > item.getProduct().getStock()) {
            throw new BadRequestException("Requested quantity exceeds available stock (" + item.getProduct().getStock() + ")");
        }

        item.setQuantity(quantity);
        CartItem updated = cartItemRepository.save(item);
        return CartItemResponse.fromEntity(updated);
    }

    public void removeItem(User user, Long itemId) {
        CartItem item = cartItemRepository.findByIdAndUser(itemId, user)
                .orElseThrow(() -> new ResourceNotFoundException("Cart item not found with id: " + itemId));
        cartItemRepository.delete(item);
    }

    public void clearCart(User user) {
        cartItemRepository.deleteByUser(user);
    }
}
