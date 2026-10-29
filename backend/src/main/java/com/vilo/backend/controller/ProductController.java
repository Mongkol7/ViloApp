package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.ProductResponse;
import com.vilo.backend.dto.CreateProductRequest;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping({"/api/v1/products", "/api/products"})
public class ProductController {

    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @PostMapping({"", "/"})
    public ResponseEntity<ApiResponse<ProductResponse>> createProduct(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody CreateProductRequest request
    ) {
        ProductResponse product = productService.createProduct(currentUser, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Product published successfully", product));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> getProducts(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "id,desc") String sort
    ) {
        String[] sortParams = sort.split(",");
        String sortProperty = sortParams[0];
        Sort.Direction direction = (sortParams.length > 1 && sortParams[1].equalsIgnoreCase("asc"))
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;

        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortProperty));
        Page<ProductResponse> products = productService.getProducts(categoryId, minPrice, maxPrice, query, pageable);
        return ResponseEntity.ok(ApiResponse.ok("Products retrieved successfully", products));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductResponse>> getProductById(@PathVariable Long id) {
        ProductResponse product = productService.getProductById(id);
        return ResponseEntity.ok(ApiResponse.ok("Product details retrieved", product));
    }

    @GetMapping("/by-video/{videoId}")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getProductsByVideo(@PathVariable Long videoId) {
        List<ProductResponse> products = productService.getProductsByVideoId(videoId);
        return ResponseEntity.ok(ApiResponse.ok("Linked products retrieved", products));
    }

    @GetMapping("/by-seller/{sellerId}")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getProductsBySeller(@PathVariable Long sellerId) {
        List<ProductResponse> products = productService.getProductsBySellerId(sellerId);
        return ResponseEntity.ok(ApiResponse.ok("Seller products retrieved", products));
    }

    @PostMapping("/{id}/deduct-stock")
    public ResponseEntity<ApiResponse<ProductResponse>> deductStock(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1") int quantity
    ) {
        ProductResponse product = productService.deductStock(id, quantity);
        return ResponseEntity.ok(ApiResponse.ok("Stock deducted successfully", product));
    }

    @PostMapping("/{id}/restore-stock")
    public ResponseEntity<ApiResponse<ProductResponse>> restoreStock(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1") int quantity
    ) {
        ProductResponse product = productService.restoreStock(id, quantity);
        return ResponseEntity.ok(ApiResponse.ok("Stock restored successfully", product));
    }
}
