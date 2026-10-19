package com.vilo.backend.repository;

import com.vilo.backend.entity.CartItem;
import com.vilo.backend.entity.Product;
import com.vilo.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    List<CartItem> findByUserOrderByCreatedAtDesc(User user);

    Optional<CartItem> findByUserAndProduct(User user, Product product);

    Optional<CartItem> findByIdAndUser(Long id, User user);

    void deleteByUser(User user);

    void deleteByIdAndUser(Long id, User user);
}
