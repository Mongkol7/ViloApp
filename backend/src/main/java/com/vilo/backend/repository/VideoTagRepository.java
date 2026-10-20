package com.vilo.backend.repository;

import com.vilo.backend.entity.VideoTag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VideoTagRepository extends JpaRepository<VideoTag, Long> {
    List<VideoTag> findByVideoId(Long videoId);
    
    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT t.tagName FROM VideoTag t WHERE LOWER(t.tagName) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<String> searchTagNames(@org.springframework.data.repository.query.Param("query") String query, org.springframework.data.domain.Pageable pageable);
}
