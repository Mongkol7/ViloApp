package com.vilo.backend.repository;

import com.vilo.backend.entity.SearchHistory;
import com.vilo.backend.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SearchHistoryRepository extends JpaRepository<SearchHistory, Long> {

    List<SearchHistory> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    void deleteByUser(User user);

    void deleteByIdAndUser(Long id, User user);

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("DELETE FROM SearchHistory s WHERE s.user = :user AND LOWER(s.query) = LOWER(:query)")
    void deleteByUserAndQuery(@org.springframework.data.repository.query.Param("user") User user, @org.springframework.data.repository.query.Param("query") String query);
}
