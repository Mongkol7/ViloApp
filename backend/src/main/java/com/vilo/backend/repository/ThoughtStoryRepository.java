package com.vilo.backend.repository;

import com.vilo.backend.entity.ThoughtStory;
import com.vilo.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface ThoughtStoryRepository extends JpaRepository<ThoughtStory, Long> {

    @Query("SELECT s FROM ThoughtStory s WHERE s.expiresAt > :now ORDER BY s.createdAt DESC")
    List<ThoughtStory> findAllActive(@Param("now") Instant now);

    @Query("SELECT s FROM ThoughtStory s WHERE (s.user IN :users OR s.user = :currentUser) AND s.expiresAt > :now ORDER BY s.createdAt DESC")
    List<ThoughtStory> findActiveForUsersAndSelf(
            @Param("users") Collection<User> users,
            @Param("currentUser") User currentUser,
            @Param("now") Instant now
    );

    @Query("SELECT s FROM ThoughtStory s WHERE s.user = :user AND s.expiresAt > :now ORDER BY s.createdAt DESC")
    List<ThoughtStory> findActiveByUser(@Param("user") User user, @Param("now") Instant now);

    Optional<ThoughtStory> findTopByUserAndExpiresAtAfterOrderByCreatedAtDesc(User user, Instant now);
}
