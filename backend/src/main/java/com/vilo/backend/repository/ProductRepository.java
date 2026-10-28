package com.vilo.backend.repository;

import com.vilo.backend.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    @Query("SELECT p FROM Product p WHERE " +
           "p.stock > 0 AND " +
           "(:categoryId IS NULL OR p.category.id = :categoryId) AND " +
           "(:minPrice IS NULL OR p.price >= :minPrice) AND " +
           "(:maxPrice IS NULL OR p.price <= :maxPrice) AND " +
           "(:queryPattern IS NULL OR LOWER(p.title) LIKE :queryPattern OR LOWER(p.description) LIKE :queryPattern)")
    Page<Product> filterProducts(
            @Param("categoryId") Long categoryId,
            @Param("minPrice") BigDecimal minPrice,
            @Param("maxPrice") BigDecimal maxPrice,
            @Param("queryPattern") String queryPattern,
            Pageable pageable
    );

    @Query("SELECT p FROM Product p JOIN p.videoIds v WHERE v = :videoId")
    List<Product> findByVideoId(@Param("videoId") Long videoId);

    List<Product> findBySellerId(Long sellerId);

    List<Product> findByCategoryId(Long categoryId);
}
