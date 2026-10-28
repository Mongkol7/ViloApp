package com.vilo.backend.repository;

import com.vilo.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    Optional<User> findByUsernameOrEmail(String username, String email);

    @org.springframework.data.jpa.repository.Query("SELECT u FROM User u WHERE LOWER(u.username) = LOWER(:value)")
    Optional<User> findByUsernameIgnoreCase(@org.springframework.data.repository.query.Param("value") String value);

    @org.springframework.data.jpa.repository.Query("SELECT u FROM User u WHERE LOWER(u.displayName) = LOWER(:value)")
    java.util.List<User> findByDisplayNameIgnoreCase(@org.springframework.data.repository.query.Param("value") String value);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);

    @org.springframework.data.jpa.repository.Query("SELECT u FROM User u WHERE LOWER(u.username) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(u.displayName) LIKE LOWER(CONCAT('%', :query, '%'))")
    java.util.List<User> searchUsers(@org.springframework.data.repository.query.Param("query") String query, org.springframework.data.domain.Pageable pageable);

    @org.springframework.data.jpa.repository.Query("SELECT f.id FROM User u JOIN u.following f WHERE u.id = :userId")
    java.util.List<Long> findFollowingIdsByUserId(@org.springframework.data.repository.query.Param("userId") Long userId);
}
