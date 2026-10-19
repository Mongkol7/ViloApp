package com.vilo.backend.service;

import com.vilo.backend.dto.VideoResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.VideoLike;
import com.vilo.backend.entity.VideoSave;
import com.vilo.backend.entity.VideoTag;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.repository.VideoLikeRepository;
import com.vilo.backend.repository.VideoRepository;
import com.vilo.backend.repository.VideoSaveRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class VideoService {

    private final VideoRepository videoRepository;
    private final UserRepository userRepository;
    private final VideoLikeRepository videoLikeRepository;
    private final VideoSaveRepository videoSaveRepository;
    private final FileStorageService fileStorageService;

    public VideoService(VideoRepository videoRepository,
                        UserRepository userRepository,
                        VideoLikeRepository videoLikeRepository,
                        VideoSaveRepository videoSaveRepository,
                        FileStorageService fileStorageService) {
        this.videoRepository = videoRepository;
        this.userRepository = userRepository;
        this.videoLikeRepository = videoLikeRepository;
        this.videoSaveRepository = videoSaveRepository;
        this.fileStorageService = fileStorageService;
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getVideoFeed(String type, User currentUser, int page, int size) {
        final User reloadedUser = (currentUser != null && currentUser.getId() != null)
                ? userRepository.findById(currentUser.getId()).orElse(currentUser)
                : null;

        String feedType = type != null ? type.toUpperCase() : "FOR_YOU";
        Page<Video> videoPage;

        if ("FOLLOWING".equals(feedType)) {
            if (reloadedUser != null && reloadedUser.getFollowing() != null && !reloadedUser.getFollowing().isEmpty()) {
                videoPage = videoRepository.findByCreatorInOrderByCreatedAtDesc(
                        reloadedUser.getFollowing(),
                        PageRequest.of(page, size)
                );
            } else {
                videoPage = videoRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(page, size));
            }
        } else {
            videoPage = videoRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(page, size));
        }

        Long currentUserId = reloadedUser != null ? reloadedUser.getId() : null;

        return videoPage.getContent().stream()
                .map(v -> {
                    VideoResponse resp = VideoResponse.fromEntity(v, reloadedUser);
                    if (currentUserId != null) {
                        resp.setLiked(isLikedBy(v.getId(), currentUserId));
                        resp.setSaved(isSavedBy(v.getId(), currentUserId));
                    }
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<Video> getFeed(String type, List<Long> followingIds, Pageable pageable) {
        if ("following".equalsIgnoreCase(type) && followingIds != null && !followingIds.isEmpty()) {
            return videoRepository.findByCreatorIdIn(followingIds, pageable);
        }
        return videoRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getUserVideos(Long userId, User currentUser) {
        return getUserVideos(String.valueOf(userId), currentUser);
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getUserVideos(String identifier, User currentUser) {
        final User reloadedUser = (currentUser != null && currentUser.getId() != null)
                ? userRepository.findById(currentUser.getId()).orElse(currentUser)
                : null;

        User targetUser = null;
        try {
            Long id = Long.valueOf(identifier);
            targetUser = userRepository.findById(id).orElse(null);
        } catch (NumberFormatException ignored) {}

        if (targetUser == null) {
            String clean = identifier.startsWith("@") ? identifier.substring(1) : identifier;
            targetUser = userRepository.findByUsername(clean).orElse(null);
        }

        if (targetUser == null) {
            return Collections.emptyList();
        }

        List<Video> videos = videoRepository.findByCreatorOrderByCreatedAtDesc(targetUser);
        Long currentUserId = reloadedUser != null ? reloadedUser.getId() : null;

        return videos.stream()
                .map(v -> {
                    VideoResponse resp = VideoResponse.fromEntity(v, reloadedUser);
                    if (currentUserId != null) {
                        resp.setLiked(isLikedBy(v.getId(), currentUserId));
                        resp.setSaved(isSavedBy(v.getId(), currentUserId));
                    }
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getSavedVideos(User currentUser) {
        if (currentUser == null || currentUser.getId() == null) {
            return Collections.emptyList();
        }
        final User reloadedUser = userRepository.findById(currentUser.getId()).orElse(currentUser);
        List<VideoSave> saves = videoSaveRepository.findByUserIdOrderByCreatedAtDesc(reloadedUser.getId());
        if (saves.isEmpty()) {
            return Collections.emptyList();
        }

        List<Long> videoIds = saves.stream().map(s -> s.getVideoId()).toList();
        Map<Long, Video> videoMap = videoRepository.findAllById(videoIds).stream()
                .collect(Collectors.toMap(v -> v.getId(), v -> v));

        return videoIds.stream()
                .map(videoMap::get)
                .filter(Objects::nonNull)
                .map(v -> {
                    VideoResponse resp = VideoResponse.fromEntity(v, reloadedUser);
                    resp.setSaved(true);
                    resp.setLiked(isLikedBy(v.getId(), reloadedUser.getId()));
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getLikedVideos(Long userId, User currentUser) {
        if (userId == null) {
            return Collections.emptyList();
        }
        final User reloadedUser = (currentUser != null && currentUser.getId() != null)
                ? userRepository.findById(currentUser.getId()).orElse(currentUser)
                : null;
        List<VideoLike> likes = videoLikeRepository.findByUserIdOrderByCreatedAtDesc(userId);
        if (likes.isEmpty()) {
            return Collections.emptyList();
        }

        List<Long> videoIds = likes.stream().map(l -> l.getVideoId()).toList();
        Map<Long, Video> videoMap = videoRepository.findAllById(videoIds).stream()
                .collect(Collectors.toMap(v -> v.getId(), v -> v));

        Long currentUserId = reloadedUser != null ? reloadedUser.getId() : null;

        return videoIds.stream()
                .map(videoMap::get)
                .filter(Objects::nonNull)
                .map(v -> {
                    VideoResponse resp = VideoResponse.fromEntity(v, reloadedUser);
                    if (currentUserId != null) {
                        resp.setLiked(isLikedBy(v.getId(), currentUserId));
                        resp.setSaved(isSavedBy(v.getId(), currentUserId));
                    }
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getUserLikedVideos(String identifier, User currentUser) {
        User targetUser = null;
        try {
            Long id = Long.valueOf(identifier);
            targetUser = userRepository.findById(id).orElse(null);
        } catch (NumberFormatException ignored) {}

        if (targetUser == null) {
            String clean = identifier.startsWith("@") ? identifier.substring(1) : identifier;
            targetUser = userRepository.findByUsername(clean).orElse(null);
        }

        if (targetUser == null) {
            return Collections.emptyList();
        }

        return getLikedVideos(targetUser.getId(), currentUser);
    }

    @Transactional(readOnly = true)
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
    public Video createVideo(Long creatorId, String title, String description, String caption,
                            MultipartFile videoFile, List<MultipartFile> mediaFiles, String directPath,
                            MultipartFile thumbnailFile, String thumbnailPath, List<String> tags) {
        User creator = userRepository.findById(creatorId)
                .orElseThrow(() -> new ResourceNotFoundException("Creator not found with id: " + creatorId));

        String videoUrl;
        boolean isImage = false;

        List<MultipartFile> nonNullMediaFiles = new ArrayList<>();
        if (mediaFiles != null) {
            for (MultipartFile f : mediaFiles) {
                if (f != null && !f.isEmpty()) {
                    nonNullMediaFiles.add(f);
                }
            }
        }

        if (nonNullMediaFiles.size() > 1) {
            List<String> storedUrls = new ArrayList<>();
            for (MultipartFile f : nonNullMediaFiles) {
                boolean isImg = isImageFile(f.getOriginalFilename(), f.getContentType());
                String subDir = isImg ? "photos" : "videos";
                storedUrls.add(fileStorageService.storeFile(f, subDir));
            }
            videoUrl = String.join(",", storedUrls);
            isImage = true;
        } else if (nonNullMediaFiles.size() == 1) {
            MultipartFile file = nonNullMediaFiles.get(0);
            isImage = isImageFile(file.getOriginalFilename(), file.getContentType());
            String subDir = isImage ? "photos" : "videos";
            videoUrl = fileStorageService.storeFile(file, subDir);
        } else if (videoFile != null && !videoFile.isEmpty()) {
            isImage = isImageFile(videoFile.getOriginalFilename(), videoFile.getContentType());
            String subDir = isImage ? "photos" : "videos";
            videoUrl = fileStorageService.storeFile(videoFile, subDir);
        } else if (directPath != null && !directPath.isBlank()) {
            isImage = isImageFile(directPath, null);
            videoUrl = normalizeVideoPath(directPath);
        } else {
            throw new IllegalArgumentException("Either video/photo file(s) or video/photo path must be provided");
        }

        String thumbnailUrl = null;
        if (thumbnailFile != null && !thumbnailFile.isEmpty()) {
            String thumbDir = fileStorageService.getThumbnailDirectoryName();
            thumbnailUrl = fileStorageService.storeFile(thumbnailFile, thumbDir);
        } else if (thumbnailPath != null && !thumbnailPath.isBlank()) {
            thumbnailUrl = normalizeThumbnailPath(thumbnailPath);
        } else if (isImage) {
            thumbnailUrl = videoUrl.contains(",") ? videoUrl.split(",")[0].trim() : videoUrl;
        }

        String effectiveCaption = caption;
        if ((effectiveCaption == null || effectiveCaption.isBlank()) && (title != null || description != null)) {
            effectiveCaption = ((title != null ? title : "") + (description != null && !description.isBlank() ? " " + description : "")).trim();
        }

        Video video = new Video(creator, title, description, effectiveCaption, videoUrl, thumbnailUrl);

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
    public Video createVideo(Long creatorId, String title, String description, String caption,
                            MultipartFile videoFile, String directPath,
                            MultipartFile thumbnailFile, String thumbnailPath, List<String> tags) {
        return createVideo(creatorId, title, description, caption, videoFile, null, directPath, thumbnailFile, thumbnailPath, tags);
    }

    @Transactional
    public Video createVideo(Long creatorId, String caption, MultipartFile videoFile, String directPath,
                            MultipartFile thumbnailFile, String thumbnailPath, List<String> tags) {
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
        if (video.getCreatorId() == null || !video.getCreatorId().equals(requesterId)) {
            throw new SecurityException("Unauthorized: You can only delete your own videos.");
        }

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
            return false;
        } else {
            videoLikeRepository.save(new VideoLike(userId, videoId));
            video.setLikeCount(video.getLikeCount() + 1);
            videoRepository.save(video);
            return true;
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
            return false;
        } else {
            videoSaveRepository.save(new VideoSave(userId, videoId));
            video.setSaveCount(video.getSaveCount() + 1);
            videoRepository.save(video);
            return true;
        }
    }

    @Transactional
    public void incrementViewCount(Long videoId) {
        Video video = getVideoById(videoId);
        video.setViewCount(video.getViewCount() + 1);
        videoRepository.save(video);
    }

    @Transactional(readOnly = true)
    public boolean isLikedBy(Long videoId, Long userId) {
        if (userId == null) return false;
        return videoLikeRepository.existsByUserIdAndVideoId(userId, videoId);
    }

    @Transactional(readOnly = true)
    public boolean isSavedBy(Long videoId, Long userId) {
        if (userId == null) return false;
        return videoSaveRepository.existsByUserIdAndVideoId(userId, videoId);
    }
}
