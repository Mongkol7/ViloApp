package com.vilo.backend.service;

import com.vilo.backend.dto.CategoryResponse;
import com.vilo.backend.dto.CreateProductRequest;
import com.vilo.backend.dto.ProductResponse;
import com.vilo.backend.entity.Category;
import com.vilo.backend.entity.Product;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.CategoryRepository;
import com.vilo.backend.repository.ProductRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;

    public ProductService(ProductRepository productRepository, CategoryRepository categoryRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
    }

    public Page<ProductResponse> getProducts(Long categoryId, BigDecimal minPrice, BigDecimal maxPrice, String query, Pageable pageable) {
        String trimmedQuery = (query != null && !query.trim().isEmpty()) ? query.trim() : null;
        if (categoryId == null && minPrice == null && maxPrice == null && trimmedQuery == null) {
            return productRepository.findAll(pageable).map(ProductResponse::fromEntity);
        }
        String queryPattern = (trimmedQuery != null) ? "%" + trimmedQuery.toLowerCase() + "%" : null;
        Page<Product> productPage = productRepository.filterProducts(categoryId, minPrice, maxPrice, queryPattern, pageable);
        return productPage.map(ProductResponse::fromEntity);
    }

    public ProductResponse getProductById(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + id));
        return ProductResponse.fromEntity(product);
    }

    @Transactional
    public ProductResponse createProduct(User seller, CreateProductRequest request) {
        String categoryName = request.getCategoryName().trim();
        Category category = categoryRepository.findByNameIgnoreCase(categoryName)
                .orElseGet(() -> createCategory(categoryName));
        List<String> images = new ArrayList<>();
        if (request.getImageUrl() != null && !request.getImageUrl().isBlank()) {
            images.add(request.getImageUrl().trim());
        }

        Product product = Product.builder()
                .title(request.getTitle().trim())
                .description(request.getDescription() == null ? "" : request.getDescription().trim())
                .price(request.getPrice())
                .originalPrice(request.getOriginalPrice())
                .stock(request.getStock())
                .rating(0.0)
                .reviewCount(0)
                .salesCount(0)
                .category(category)
                .seller(seller)
                .images(images)
                .build();
        return ProductResponse.fromEntity(productRepository.save(product));
    }

    private Category createCategory(String name) {
        String slug = name.toLowerCase().replaceAll("[^a-z0-9]+", "-")
                .replaceAll("(^-|-$)", "");
        if (slug.isBlank()) {
            throw new BadRequestException("Category name must contain letters or numbers");
        }
        if (categoryRepository.existsBySlug(slug)) {
            slug = slug + "-" + System.nanoTime();
        }
        return categoryRepository.save(Category.builder().name(name).slug(slug).build());
    }

    public List<CategoryResponse> getCategories() {
        return categoryRepository.findAll().stream()
                .map(CategoryResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<ProductResponse> getProductsByVideoId(Long videoId) {
        return productRepository.findByVideoId(videoId).stream()
                .map(ProductResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<ProductResponse> getProductsBySellerId(Long sellerId) {
        return productRepository.findBySellerId(sellerId).stream()
                .map(ProductResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<ProductResponse> getProductsByCategoryId(Long categoryId) {
        return productRepository.findByCategoryId(categoryId).stream()
                .map(ProductResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ProductResponse deductStock(Long id, int quantity) {
        if (quantity <= 0) {
            throw new BadRequestException("Quantity must be greater than zero");
        }
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + id));
        if (product.getStock() < quantity) {
            throw new BadRequestException("Insufficient stock for product: " + product.getTitle() +
                    " (Requested: " + quantity + ", Available: " + product.getStock() + ")");
        }
        product.setStock(product.getStock() - quantity);
        product.setSalesCount(product.getSalesCount() + quantity);
        return ProductResponse.fromEntity(productRepository.save(product));
    }

    @Transactional
    public ProductResponse restoreStock(Long id, int quantity) {
        if (quantity <= 0) {
            throw new BadRequestException("Quantity must be greater than zero");
        }
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + id));
        product.setStock(product.getStock() + quantity);
        product.setSalesCount(Math.max(0, product.getSalesCount() - quantity));
        return ProductResponse.fromEntity(productRepository.save(product));
    }
}
