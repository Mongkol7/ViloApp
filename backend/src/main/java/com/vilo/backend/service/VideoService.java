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

    public boolean isImageFile(String filenameOrPath, String contentType) {
        if (contentType != null && contentType.toLowerCase().startsWith("image/")) {
            return true;
        }
        if (filenameOrPath != null) {
            String lower = filenameOrPath.toLowerCase().trim();
            return lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png")
                    || lower.endsWith(".webp") || lower.endsWith(".gif") || lower.endsWith(".bmp");
        }
        return false;
    }

    public String normalizeVideoPath(String rawPath) {
        if (rawPath == null || rawPath.isBlank()) {
            return null;
        }
        String path = rawPath.trim().replace('\\', '/');
        if (path.startsWith("/uploads/") || path.startsWith("assets/") || path.startsWith("http://") || path.startsWith("https://")) {
            return path;
        }
        if (path.startsWith("uploads/")) {
            return "/" + path;
        }
        if (path.startsWith("/")) {
            path = path.substring(1);
        }
        if (path.startsWith("photos/")) {
            return "/uploads/" + path;
        }
        if (path.startsWith("videos/")) {
            return "/uploads/" + path;
        }
        if (isImageFile(path, null)) {
            return "/uploads/photos/" + path;
        }
        return "/uploads/videos/" + path;
    }

    public String normalizeThumbnailPath(String rawPath) {
        if (rawPath == null || rawPath.isBlank()) {
            return null;
        }
        String path = rawPath.trim().replace('\\', '/');
        if (path.startsWith("/uploads/") || path.startsWith("assets/") || path.startsWith("http://") || path.startsWith("https://")) {
            return path;
        }
        if (path.startsWith("uploads/")) {
            return "/" + path;
        }
        if (path.startsWith("/")) {
            path = path.substring(1);
        }
        if (path.startsWith("thumbnails/") || path.startsWith("thumnail/") || path.startsWith("thumbnail/") || path.startsWith("photos/")) {
            return "/uploads/" + path;
        }
        String thumbDir = fileStorageService.getThumbnailDirectoryName();
        return "/uploads/" + thumbDir + "/" + path;
    }

    @Transactional
    public Video createVideo(Long creatorId, String title, String description, String caption, MultipartFile videoFile, String directPath, MultipartFile thumbnailFile, String thumbnailPath, List<String> tags) {
        String videoUrl;
        boolean isImage = false;
        if (videoFile != null && !videoFile.isEmpty()) {
            isImage = isImageFile(videoFile.getOriginalFilename(), videoFile.getContentType());
            String subDir = isImage ? "photos" : "videos";
            videoUrl = fileStorageService.storeFile(videoFile, subDir);
        } else if (directPath != null && !directPath.isBlank()) {
            isImage = isImageFile(directPath, null);
            videoUrl = normalizeVideoPath(directPath);
        } else {
            throw new IllegalArgumentException("Either video/photo file or video/photo path must be provided");
        }

        String thumbnailUrl = null;
        if (thumbnailFile != null && !thumbnailFile.isEmpty()) {
            String thumbDir = fileStorageService.getThumbnailDirectoryName();
            thumbnailUrl = fileStorageService.storeFile(thumbnailFile, thumbDir);
        } else if (thumbnailPath != null && !thumbnailPath.isBlank()) {
            thumbnailUrl = normalizeThumbnailPath(thumbnailPath);
        } else if (isImage) {
            // For photo posts without explicit thumbnail, auto-assign the photo URL as thumbnail
            thumbnailUrl = videoUrl;
        }

        String effectiveCaption = caption;
        if ((effectiveCaption == null || effectiveCaption.isBlank()) && (title != null || description != null)) {
            effectiveCaption = ((title != null ? title : "") + (description != null && !description.isBlank() ? " " + description : "")).trim();
        }

        Video video = new Video(creatorId, title, description, effectiveCaption, videoUrl, thumbnailUrl);

        if (tags != null) {
            for (String tag : tags) {
                if (tag != null && !tag.isBlank()) {
                    video.getTags().add(new VideoTag(video, tag.trim().replaceAll("^#", "")));
                }
            }
        }

        return videoRepository.save(video);
    }

    @Transactional
    public Video createVideo(Long creatorId, String caption, MultipartFile videoFile, String directPath, MultipartFile thumbnailFile, String thumbnailPath, List<String> tags) {
        return createVideo(creatorId, null, null, caption, videoFile, directPath, thumbnailFile, thumbnailPath, tags);
    }

    @Transactional
    public Video uploadVideo(Long creatorId, String caption, MultipartFile videoFile, MultipartFile thumbnailFile, List<String> tags) {
        return createVideo(creatorId, caption, videoFile, null, thumbnailFile, null, tags);
    }

    @Transactional
    public Video createVideoFromPath(Long creatorId, String caption, String videoPath, List<String> tags) {
        return createVideo(creatorId, caption, null, videoPath, null, null, tags);
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
