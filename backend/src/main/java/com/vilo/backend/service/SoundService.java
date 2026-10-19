package com.vilo.backend.service;

import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.dto.VideoResponse;
import com.vilo.backend.entity.Sound;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.SoundRepository;
import com.vilo.backend.repository.VideoRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
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
    public List<SoundResponse> getAllSounds() {
        List<Sound> sounds = soundRepository.findAllByOrderByUsageCountDesc();
        return sounds.stream().map(s -> {
            long count = videoRepository.countBySoundId(s.getId());
            if (count > 0 || s.getUsageCount() == null || s.getUsageCount() == 0) {
                s.setUsageCount(Math.max(s.getUsageCount() != null ? s.getUsageCount() : 0L, count));
            }
            return SoundResponse.fromEntity(s);
        }).collect(Collectors.toList());
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
        long count = videoRepository.countBySoundId(sound.getId());
        if (count > 0) {
            sound.setUsageCount(Math.max(sound.getUsageCount() != null ? sound.getUsageCount() : 0L, count));
        }
        return SoundResponse.fromEntity(sound);
    }

    @Transactional
    public Map<String, Object> getSoundWithVideos(Long soundId, User currentUser) {
        Sound sound = soundRepository.findById(soundId)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + soundId));

        List<Video> videos = videoRepository.findBySoundIdOrderByCreatedAtDesc(soundId);
        if (videos.isEmpty() && sound.getTitle() != null && !sound.getTitle().isBlank()) {
            videos = videoRepository.findByMusicTitleContainingIgnoreCase(sound.getTitle());
        }

        long actualCount = Math.max((long) videos.size(), videoRepository.countBySoundId(soundId));
        if (actualCount > 0 && (sound.getUsageCount() == null || sound.getUsageCount() < actualCount)) {
            sound.setUsageCount(actualCount);
            soundRepository.save(sound);
        }

        List<VideoResponse> videoDtos = videos.stream()
                .map(v -> VideoResponse.fromEntity(v, currentUser))
                .collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("sound", SoundResponse.fromEntity(sound));
        result.put("videos", videoDtos);
        // For backwards compatibility with callers expecting a flat list of video items
        result.put("data", videoDtos);
        return result;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getVideosBySoundId(Long soundId) {
        Sound sound = soundRepository.findById(soundId)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + soundId));

        List<Video> videos = videoRepository.findBySoundIdOrderByCreatedAtDesc(soundId);
        if (videos.isEmpty() && sound.getTitle() != null && !sound.getTitle().isBlank()) {
            videos = videoRepository.findByMusicTitleContainingIgnoreCase(sound.getTitle());
        }

        if (!videos.isEmpty()) {
            return videos.stream().map(v -> {
                Map<String, Object> item = new HashMap<>();
                item.put("id", v.getId().toString());
                item.put("thumbnailUrl", v.getThumbnailUrl());
                item.put("videoUrl", v.getVideoUrl());
                item.put("views", v.getLikeCount() != null ? v.getLikeCount().toString() : "0");
                item.put("soundId", soundId);
                item.put("soundTitle", sound.getTitle());
                return item;
            }).collect(Collectors.toList());
        }

        return Collections.emptyList();
    }

    @Transactional(readOnly = true)
    public List<SoundResponse> getUserSounds(Long userId, String username) {
        List<Sound> sounds = new ArrayList<>();
        if (userId != null) {
            sounds = soundRepository.findByCreatorIdOrderByCreatedAtDesc(userId);
        }
        if (sounds.isEmpty() && username != null && !username.isBlank()) {
            String clean = username.replaceAll("^@", "").trim();
            sounds = soundRepository.findByCreatorUsernameIgnoreCaseOrderByCreatedAtDesc(clean);
        }

        return sounds.stream().map(s -> {
            long count = videoRepository.countBySoundId(s.getId());
            if (count > 0) {
                s.setUsageCount(Math.max(s.getUsageCount() != null ? s.getUsageCount() : 0L, count));
            }
            return SoundResponse.fromEntity(s);
        }).collect(Collectors.toList());
    }
}
