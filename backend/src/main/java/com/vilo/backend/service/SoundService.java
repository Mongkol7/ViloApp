package com.vilo.backend.service;

import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.entity.Sound;
import com.vilo.backend.entity.Video;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.SoundRepository;
import com.vilo.backend.repository.VideoRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SoundService {

    private final SoundRepository soundRepository;
    private final VideoRepository videoRepository;

    public SoundService(SoundRepository soundRepository, VideoRepository videoRepository) {
        this.soundRepository = soundRepository;
        this.videoRepository = videoRepository;
    }

    @Transactional(readOnly = true)
    public List<SoundResponse> getTrendingSounds() {
        List<Sound> sounds = soundRepository.findByIsTrendingTrueOrderByUsageCountDesc();
        if (sounds.isEmpty()) {
            sounds = soundRepository.findAllByOrderByUsageCountDesc(PageRequest.of(0, 10));
        }
        return sounds.stream().map(SoundResponse::fromEntity).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SoundResponse getSoundById(Long id) {
        Sound sound = soundRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + id));
        return SoundResponse.fromEntity(sound);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getVideosBySoundId(Long soundId) {
        // Verify sound exists
        Sound sound = soundRepository.findById(soundId)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + soundId));

        List<Video> matchingVideos = videoRepository
                .findByMusicTitleContainingIgnoreCaseOrderByCreatedAtDesc(sound.getTitle());
        List<Map<String, Object>> videos = new java.util.ArrayList<>();

        for (Video source : matchingVideos) {
            Map<String, Object> video = new HashMap<>();
            video.put("id", source.getId());
            String thumbnailUrl = source.getThumbnailUrl();
            if ((thumbnailUrl == null || thumbnailUrl.isBlank())
                    && source.getVideoUrl() != null
                    && !source.getVideoUrl().contains(",")) {
                thumbnailUrl = source.getVideoUrl();
            }
            video.put("thumbnailUrl", thumbnailUrl);
            long views = source.getViewCount() != null ? source.getViewCount() : 0L;
            video.put("views", formatCount(views));
            video.put("viewCount", views);
            video.put("videoUrl", source.getVideoUrl());
            video.put("soundId", soundId);
            video.put("soundTitle", sound.getTitle());
            videos.add(video);
        }

        return videos;
    }

    private String formatCount(long count) {
        if (count >= 1_000_000) return String.format("%.1fM", count / 1_000_000.0);
        if (count >= 1_000) return String.format("%.1fK", count / 1_000.0);
        return String.valueOf(count);
    }
}
