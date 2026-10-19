package com.vilo.backend.service;

import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.VideoLike;
import com.vilo.backend.entity.VideoSave;
import com.vilo.backend.entity.VideoTag;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.VideoLikeRepository;
import com.vilo.backend.repository.VideoRepository;
import com.vilo.backend.repository.VideoSaveRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
public class VideoService {

    private final VideoRepository videoRepository;
    private final VideoLikeRepository videoLikeRepository;
    private final VideoSaveRepository videoSaveRepository;
    private final FileStorageService fileStorageService;

    public VideoService(VideoRepository videoRepository,
                        VideoLikeRepository videoLikeRepository,
                        VideoSaveRepository videoSaveRepository,
                        FileStorageService fileStorageService) {
        this.videoRepository = videoRepository;
        this.videoLikeRepository = videoLikeRepository;
        this.videoSaveRepository = videoSaveRepository;
        this.fileStorageService = fileStorageService;
    }

    public Page<Video> getFeed(String type, List<Long> followingIds, Pageable pageable) {
        if ("following".equalsIgnoreCase(type) && followingIds != null && !followingIds.isEmpty()) {
            return videoRepository.findByCreatorIdIn(followingIds, pageable);
        }
        // Default to "foryou" global feed ordered by recent creation
        return videoRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    public Video getVideoById(Long id) {
        return videoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Video not found with id: " + id));
    }

    @Transactional
    public Video uploadVideo(Long creatorId, String caption, MultipartFile videoFile, MultipartFile thumbnailFile, List<String> tags) {
        String videoUrl = fileStorageService.storeFile(videoFile, "videos");
        
        String thumbnailUrl = null;
        if (thumbnailFile != null && !thumbnailFile.isEmpty()) {
            thumbnailUrl = fileStorageService.storeFile(thumbnailFile, "thumbnails");
        }

        Video video = new Video(creatorId, caption, videoUrl, thumbnailUrl);
        
        if (tags != null) {
            for (String tag : tags) {
                video.getTags().add(new VideoTag(video, tag.trim()));
            }
        }

        return videoRepository.save(video);
    }

    @Transactional
    public void deleteVideo(Long videoId, Long requesterId) {
        Video video = getVideoById(videoId);
        if (!video.getCreatorId().equals(requesterId)) {
            throw new SecurityException("Unauthorized: You can only delete your own videos.");
        }

        // Delete physical media files
        fileStorageService.deleteFile(video.getVideoUrl());
        if (video.getThumbnailUrl() != null) {
            fileStorageService.deleteFile(video.getThumbnailUrl());
        }

        videoRepository.delete(video);
    }

    @Transactional
    public boolean toggleLike(Long videoId, Long userId) {
        Video video = getVideoById(videoId);
        boolean exists = videoLikeRepository.existsByUserIdAndVideoId(userId, videoId);

        if (exists) {
            videoLikeRepository.deleteByUserIdAndVideoId(userId, videoId);
            video.setLikeCount(Math.max(0L, video.getLikeCount() - 1));
            videoRepository.save(video);
            return false; // Unliked
        } else {
            videoLikeRepository.save(new VideoLike(userId, videoId));
            video.setLikeCount(video.getLikeCount() + 1);
            videoRepository.save(video);
            return true; // Liked
        }
    }

    @Transactional
    public boolean toggleSave(Long videoId, Long userId) {
        Video video = getVideoById(videoId);
        boolean exists = videoSaveRepository.existsByUserIdAndVideoId(userId, videoId);

        if (exists) {
            videoSaveRepository.deleteByUserIdAndVideoId(userId, videoId);
            video.setSaveCount(Math.max(0L, video.getSaveCount() - 1));
            videoRepository.save(video);
            return false; // Unsaved
        } else {
            videoSaveRepository.save(new VideoSave(userId, videoId));
            video.setSaveCount(video.getSaveCount() + 1);
            videoRepository.save(video);
            return true; // Saved
        }
    }

    @Transactional
    public void incrementViewCount(Long videoId) {
        Video video = getVideoById(videoId);
        video.setViewCount(video.getViewCount() + 1);
        videoRepository.save(video);
    }

    public boolean isLikedBy(Long videoId, Long userId) {
        if (userId == null) return false;
        return videoLikeRepository.existsByUserIdAndVideoId(userId, videoId);
    }

    public boolean isSavedBy(Long videoId, Long userId) {
        if (userId == null) return false;
        return videoSaveRepository.existsByUserIdAndVideoId(userId, videoId);
    }
}
