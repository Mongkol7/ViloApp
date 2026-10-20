package com.vilo.backend.service;

import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.dto.VideoResponse;
import com.vilo.backend.entity.Sound;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.exception.ForbiddenException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.SoundRepository;
import com.vilo.backend.repository.VideoRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class SoundService {

    private final SoundRepository soundRepository;
    private final VideoRepository videoRepository;
    private final FileStorageService fileStorageService;

    public SoundService(SoundRepository soundRepository, VideoRepository videoRepository, FileStorageService fileStorageService) {
        this.soundRepository = soundRepository;
        this.videoRepository = videoRepository;
        this.fileStorageService = fileStorageService;
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


    @Transactional
    public SoundResponse uploadSound(MultipartFile audioFile, MultipartFile coverFile, String title, String artist, String coverUrl, User currentUser) {
        String storedAudioUrl = fileStorageService.storeFile(audioFile, "music");
        String soundTitle = (title != null && !title.isBlank()) ? title.trim()
                : (audioFile.getOriginalFilename() != null ? audioFile.getOriginalFilename().replaceFirst("[.][^.]+$", "") : "Original Sound");
        Long creatorId = currentUser != null ? currentUser.getId() : 1L;
        String creatorUsername = currentUser != null ? currentUser.getUsername() : "anonymous";
        String effectiveArtist = (artist != null && !artist.isBlank()) ? artist.trim() : "@" + creatorUsername;

        String storedCoverUrl = null;
        if (coverFile != null && !coverFile.isEmpty()) {
            storedCoverUrl = fileStorageService.storeFile(coverFile, "thumbnails");
        }

        String effectiveCover = (storedCoverUrl != null && !storedCoverUrl.isBlank()) ? storedCoverUrl
                : ((coverUrl != null && !coverUrl.isBlank()) ? coverUrl.trim() : "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500");

        Sound sound = new Sound(soundTitle, creatorId, creatorUsername, storedAudioUrl, effectiveCover, 0L);
        sound.setArtist(effectiveArtist);
        sound = soundRepository.save(sound);
        return SoundResponse.fromEntity(sound);
    }

    @Transactional
    public SoundResponse uploadSound(MultipartFile audioFile, String title, String artist, String coverUrl, User currentUser) {
        return uploadSound(audioFile, null, title, artist, coverUrl, currentUser);
    }

    @Transactional
    public void deleteSound(Long soundId, User currentUser) {
        Sound sound = soundRepository.findById(soundId)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + soundId));

        if (currentUser == null) {
            throw new ForbiddenException("Authentication required to delete sound");
        }

        boolean isOwner = false;
        if (sound.getCreatorId() != null && currentUser.getId() != null) {
            isOwner = sound.getCreatorId().equals(currentUser.getId());
        }
        if (!isOwner && currentUser.getUsername() != null && sound.getCreatorUsername() != null) {
            String cleanCurrent = currentUser.getUsername().replaceFirst("^@", "").trim();
            String cleanCreator = sound.getCreatorUsername().replaceFirst("^@", "").trim();
            isOwner = cleanCurrent.equalsIgnoreCase(cleanCreator);
        }

        if (!isOwner) {
            throw new ForbiddenException("Forbidden: Only the owner can delete this sound");
        }

        // Safely clear soundId on any videos referencing that sound
        List<Video> videos = videoRepository.findBySoundIdOrderByCreatedAtDesc(soundId);
        for (Video v : videos) {
            v.setSoundId(null);
        }
        videoRepository.saveAll(videos);
        videoRepository.clearSoundId(soundId);

        soundRepository.delete(sound);
    }

    @Transactional
    public SoundResponse updateSound(Long soundId, String title, MultipartFile coverFile, String coverUrl, User currentUser) {
        Sound sound = soundRepository.findById(soundId)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + soundId));

        if (currentUser == null) {
            throw new org.springframework.security.access.AccessDeniedException("Unauthorized: Authentication required to edit sound details.");
        }

        if (sound.getCreatorId() != null) {
            boolean isCreator = sound.getCreatorId().equals(currentUser.getId()) ||
                    (currentUser.getUsername() != null && currentUser.getUsername().equalsIgnoreCase(sound.getCreatorUsername()));
            if (!isCreator) {
                throw new org.springframework.security.access.AccessDeniedException("Unauthorized: Only the creator of this sound track can edit its cover or details.");
            }
        }

        if (title != null && !title.isBlank()) {
            sound.setTitle(title.trim());
        }

        if (coverFile != null && !coverFile.isEmpty()) {
            String storedCoverUrl = fileStorageService.storeFile(coverFile, "thumbnails");
            sound.setCoverUrl(storedCoverUrl);
            sound.setAlbumArtUrl(storedCoverUrl);
        } else if (coverUrl != null && !coverUrl.isBlank()) {
            sound.setCoverUrl(coverUrl.trim());
            sound.setAlbumArtUrl(coverUrl.trim());
        }

        sound = soundRepository.save(sound);
        return SoundResponse.fromEntity(sound);
    }
}
