package com.vilo.backend.repository;

import com.vilo.backend.entity.VideoSave;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface VideoSaveRepository extends JpaRepository<VideoSave, Long> {
    Optional<VideoSave> findByUserIdAndVideoId(Long userId, Long videoId);
    boolean existsByUserIdAndVideoId(Long userId, Long videoId);
    void deleteByUserIdAndVideoId(Long userId, Long videoId);
}
