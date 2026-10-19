package com.vilo.backend.repository;

import com.vilo.backend.entity.Hashtag;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface HashtagRepository extends JpaRepository<Hashtag, Long> {

    Optional<Hashtag> findByTagIgnoreCase(String tag);

    List<Hashtag> findByIsTrendingTrueOrderByUsageCountDesc();

    List<Hashtag> findAllByOrderByUsageCountDesc(Pageable pageable);

    @Query("SELECT h FROM Hashtag h WHERE LOWER(h.tag) LIKE LOWER(CONCAT('%', :query, '%')) ORDER BY h.usageCount DESC")
    List<Hashtag> searchHashtags(@Param("query") String query, Pageable pageable);
}
