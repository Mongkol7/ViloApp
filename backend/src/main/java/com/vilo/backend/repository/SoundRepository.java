package com.vilo.backend.repository;

import com.vilo.backend.entity.Sound;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SoundRepository extends JpaRepository<Sound, Long> {

    List<Sound> findByIsTrendingTrueOrderByUsageCountDesc();

    List<Sound> findAllByOrderByUsageCountDesc(Pageable pageable);

    @Query("SELECT s FROM Sound s WHERE LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(s.artist) LIKE LOWER(CONCAT('%', :query, '%')) ORDER BY s.usageCount DESC")
    List<Sound> searchSounds(@Param("query") String query, Pageable pageable);
}
