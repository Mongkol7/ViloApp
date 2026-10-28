package com.vilo.backend.service;

import com.vilo.backend.dto.CheckoutRequest;
import com.vilo.backend.dto.OrderResponse;
import com.vilo.backend.entity.*;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.CartItemRepository;
import com.vilo.backend.repository.OrderRepository;
import com.vilo.backend.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class OrderService {

    private final OrderRepository orderRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;

    public OrderService(OrderRepository orderRepository,
                        CartItemRepository cartItemRepository,
                        ProductRepository productRepository) {
        this.orderRepository = orderRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
    }

    @Transactional
    public OrderResponse checkout(User user, CheckoutRequest request) {
        List<CartItem> cartItems = cartItemRepository.findByUserOrderByCreatedAtDesc(user);
        if (cartItems.isEmpty()) {
            throw new BadRequestException("Cannot checkout with an empty cart");
        }

        BigDecimal totalAmount = BigDecimal.ZERO;

        // 1. Validate stock and calculate total
        for (CartItem item : cartItems) {
            Product product = item.getProduct();
            if (product.getStock() < item.getQuantity()) {
                throw new BadRequestException("Insufficient stock for product: " + product.getTitle() +
                        " (Requested: " + item.getQuantity() + ", Available: " + product.getStock() + ")");
            }
            BigDecimal itemTotal = product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
            totalAmount = totalAmount.add(itemTotal);
        }

        // 2. Generate unique order number: ORD-YYYYMMDD-XXXX
        String datePrefix = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);
        String randomSuffix = UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        String orderNumber = "ORD-" + datePrefix + "-" + randomSuffix;

        // 3. Create Order
        OrderStatus initialStatus = "COD".equalsIgnoreCase(request.getPaymentMethod())
                ? OrderStatus.PENDING
                : OrderStatus.PAID;

        Order order = Order.builder()
                .orderNumber(orderNumber)
                .user(user)
                .totalAmount(totalAmount)
                .status(initialStatus)
                .shippingAddress(request.getShippingAddress())
                .paymentMethod(request.getPaymentMethod())
                .notes(request.getNotes())
                .build();

        // 4. Stock reservation and order items creation
        for (CartItem item : cartItems) {
            Product product = item.getProduct();

            // Reserve stock
            product.setStock(product.getStock() - item.getQuantity());
            product.setSalesCount(product.getSalesCount() + item.getQuantity());
            productRepository.save(product);

            String firstImage = (product.getImages() != null && !product.getImages().isEmpty())
                    ? product.getImages().get(0)
                    : "";

            OrderItem orderItem = OrderItem.builder()
                    .order(order)
                    .product(product)
                    .productTitle(product.getTitle())
                    .productImageUrl(firstImage)
                    .price(product.getPrice())
                    .quantity(item.getQuantity())
                    .variant(item.getVariant())
                    .build();

            order.addOrderItem(orderItem);
        }

        Order savedOrder = orderRepository.save(order);

        // The Flutter order flow already persists the buyer's exact inquiry in
        // the canonical chat thread. Do not create a second server-generated
        // message here: that made the seller see a different/duplicate order
        // message from the one shown to the buyer.

        // 5. Clear user cart
        cartItemRepository.deleteByUser(user);

        return OrderResponse.fromEntity(savedOrder);
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> getOrderHistory(User user) {
        return orderRepository.findByUserOrderByCreatedAtDesc(user).stream()
                .map(OrderResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public OrderResponse getOrderById(User user, Long orderId) {
        Order order = orderRepository.findByIdAndUser(orderId, user)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));
        return OrderResponse.fromEntity(order);
    }
}
