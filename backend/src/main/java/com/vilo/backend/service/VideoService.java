package com.vilo.backend.service;

import com.vilo.backend.dto.VideoResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.VideoLike;
import com.vilo.backend.entity.VideoSave;
import com.vilo.backend.entity.VideoTag;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.entity.Hashtag;
import com.vilo.backend.repository.HashtagRepository;
import com.vilo.backend.repository.CommentRepository;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.repository.VideoLikeRepository;
import com.vilo.backend.repository.VideoRepository;
import com.vilo.backend.repository.VideoSaveRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
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
    private final CommentRepository commentRepository;
    private final FileStorageService fileStorageService;
    private final com.vilo.backend.repository.SoundRepository soundRepository;
    private final HashtagRepository hashtagRepository;

    public VideoService(VideoRepository videoRepository,
                        UserRepository userRepository,
                        VideoLikeRepository videoLikeRepository,
                        VideoSaveRepository videoSaveRepository,
                        CommentRepository commentRepository,
                        FileStorageService fileStorageService,
                        com.vilo.backend.repository.SoundRepository soundRepository,
                        HashtagRepository hashtagRepository) {
        this.videoRepository = videoRepository;
        this.userRepository = userRepository;
        this.videoLikeRepository = videoLikeRepository;
        this.videoSaveRepository = videoSaveRepository;
        this.commentRepository = commentRepository;
        this.fileStorageService = fileStorageService;
        this.soundRepository = soundRepository;
        this.hashtagRepository = hashtagRepository;
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getVideoFeed(String type, User currentUser, int page, int size) {
        final User reloadedUser = (currentUser != null && currentUser.getId() != null)
                ? userRepository.findById(currentUser.getId()).orElse(currentUser)
                : null;
        Long currentUserId = reloadedUser != null ? reloadedUser.getId() : null;

        Page<Video> videoPage = getFeed(type, currentUserId, PageRequest.of(page, size), null);

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
    public Page<Video> getFeed(String type, Long currentUserId, Pageable pageable, Long seed) {
        List<Video> candidateVideos;

        if ("following".equalsIgnoreCase(type)) {
            List<Long> followingIds = (currentUserId != null)
                    ? userRepository.findFollowingIdsByUserId(currentUserId)
                    : Collections.emptyList();

            if (!followingIds.isEmpty()) {
                candidateVideos = videoRepository.findAllByCreatorIdIn(followingIds);
                if (candidateVideos.isEmpty()) {
                    candidateVideos = videoRepository.findAll();
                }
            } else {
                candidateVideos = videoRepository.findAll();
            }
        } else {
            candidateVideos = videoRepository.findAll();
>>>>>>> develop
        }

        List<Video> randomizedList = interleaveAndRandomizeVideos(candidateVideos, seed);

        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageable.getPageSize(), randomizedList.size());
        List<Video> paged = (start < randomizedList.size())
                ? randomizedList.subList(start, end)
                : Collections.emptyList();

        return new PageImpl<>(paged, pageable, randomizedList.size());
    }

    @Transactional(readOnly = true)
    public Page<Video> getFeed(String type, List<Long> followingIds, Pageable pageable) {
        return getFeed(type, followingIds, pageable, null);
    }

    @Transactional(readOnly = true)
    public Page<Video> getFeed(String type, List<Long> followingIds, Pageable pageable, Long seed) {
        List<Video> candidateVideos;

        if ("following".equalsIgnoreCase(type) && followingIds != null && !followingIds.isEmpty()) {
            candidateVideos = videoRepository.findAllByCreatorIdIn(followingIds);
            if (candidateVideos.isEmpty()) {
                candidateVideos = videoRepository.findAll();
            }
        } else {
            candidateVideos = videoRepository.findAll();
        }

        List<Video> randomizedList = interleaveAndRandomizeVideos(candidateVideos, seed);

        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageable.getPageSize(), randomizedList.size());
        List<Video> paged = (start < randomizedList.size())
                ? randomizedList.subList(start, end)
                : Collections.emptyList();

        return new PageImpl<>(paged, pageable, randomizedList.size());
    }

    /**
     * Shuffles and round-robin interleaves videos across distinct creators.
     * Ensures consecutive videos are not by the same user, and distribution is randomized.
     */
    public List<Video> interleaveAndRandomizeVideos(List<Video> videos, Long seed) {
        if (videos == null || videos.isEmpty()) {
            return Collections.emptyList();
        }

        Random rng = (seed != null) ? new Random(seed) : new Random();

        // 1. Group candidate videos by creator ID
        Map<Long, List<Video>> byCreator = new LinkedHashMap<>();
        for (Video v : videos) {
            Long creatorId = (v.getCreator() != null && v.getCreator().getId() != null)
                    ? v.getCreator().getId()
                    : (v.getCreatorId() != null ? v.getCreatorId() : 0L);
            byCreator.computeIfAbsent(creatorId, k -> new ArrayList<>()).add(v);
        }

        // 2. Shuffle each creator's videos
        for (List<Video> creatorVideos : byCreator.values()) {
            Collections.shuffle(creatorVideos, rng);
        }

        // 3. Shuffle creators
        List<List<Video>> queues = new ArrayList<>(byCreator.values());
        Collections.shuffle(queues, rng);

        // 4. Interleave round-robin across creators
        List<Video> result = new ArrayList<>(videos.size());
        boolean hasMore = true;
        while (hasMore) {
            hasMore = false;
            for (List<Video> q : queues) {
                if (!q.isEmpty()) {
                    result.add(q.remove(0));
                    if (!q.isEmpty()) {
                        hasMore = true;
                    }
                }
            }
        }
        return result;
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
                            MultipartFile thumbnailFile, String thumbnailPath,
                            Long soundId, MultipartFile audioFile,
                            String musicTitle, String musicArtist, String audioUrl,
                            List<String> tags) {
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

        String imageUrls = null;
        if (nonNullMediaFiles.size() > 1) {
            List<String> storedUrls = new ArrayList<>();
            for (MultipartFile f : nonNullMediaFiles) {
                boolean isImg = isImageFile(f.getOriginalFilename(), f.getContentType());
                String subDir = isImg ? "photos" : "videos";
                storedUrls.add(fileStorageService.storeFile(f, subDir));
            }
            videoUrl = storedUrls.get(0);
            imageUrls = String.join(",", storedUrls);
            isImage = true;
        } else if (nonNullMediaFiles.size() == 1) {
            MultipartFile file = nonNullMediaFiles.get(0);
            isImage = isImageFile(file.getOriginalFilename(), file.getContentType());
            String subDir = isImage ? "photos" : "videos";
            videoUrl = fileStorageService.storeFile(file, subDir);
            if (isImage) {
                imageUrls = videoUrl;
            }
        } else if (videoFile != null && !videoFile.isEmpty()) {
            isImage = isImageFile(videoFile.getOriginalFilename(), videoFile.getContentType());
            String subDir = isImage ? "photos" : "videos";
            videoUrl = fileStorageService.storeFile(videoFile, subDir);
            if (isImage) {
                imageUrls = videoUrl;
            }
        } else if (directPath != null && !directPath.isBlank()) {
            isImage = isImageFile(directPath, null);
            videoUrl = normalizeVideoPath(directPath);
            if (isImage) {
                imageUrls = videoUrl;
            }
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
            thumbnailUrl = (imageUrls != null && imageUrls.contains(",")) ? imageUrls.split(",")[0].trim() : videoUrl;
        }

        String effectiveCaption = caption;
        if ((effectiveCaption == null || effectiveCaption.isBlank()) && (title != null || description != null)) {
            effectiveCaption = ((title != null ? title : "") + (description != null && !description.isBlank() ? " " + description : "")).trim();
        }

        String effectiveTitle = (title != null && !title.isBlank()) ? title.trim() : (effectiveCaption != null ? effectiveCaption : "");
        String effectiveDescription = (description != null && !description.isBlank()) ? description.trim() : (effectiveCaption != null ? effectiveCaption : "");

        Video video = new Video(creator, effectiveTitle, effectiveDescription, effectiveCaption, videoUrl, thumbnailUrl);
        if (imageUrls != null) {
            video.setImageUrls(imageUrls);
        }

        // Handle Optional Music / Sound
        if (audioFile != null && !audioFile.isEmpty()) {
            String storedAudioUrl = fileStorageService.storeFile(audioFile, "music");
            String soundTitle = (musicTitle != null && !musicTitle.isBlank() && !"None".equalsIgnoreCase(musicTitle))
                    ? musicTitle.trim()
                    : (audioFile.getOriginalFilename() != null ? audioFile.getOriginalFilename().replaceFirst("[.][^.]+$", "") : "Original Sound");
            com.vilo.backend.entity.Sound newSound = new com.vilo.backend.entity.Sound(
                    soundTitle,
                    creator.getId(),
                    creator.getUsername(),
                    storedAudioUrl,
                    thumbnailUrl != null ? thumbnailUrl : videoUrl,
                    1L
            );
            newSound = soundRepository.save(newSound);
            video.setSoundId(newSound.getId());
            video.setMusicTitle(newSound.getTitle());
            video.setMusicArtist("@" + creator.getUsername());
            video.setAudioUrl(storedAudioUrl);
        } else if (soundId != null) {
            Optional<com.vilo.backend.entity.Sound> soundOpt = soundRepository.findById(soundId);
            if (soundOpt.isPresent()) {
                com.vilo.backend.entity.Sound s = soundOpt.get();
                video.setSoundId(s.getId());
                video.setMusicTitle(s.getTitle());
                video.setMusicArtist(s.getArtist());
                video.setAudioUrl(s.getAudioUrl());
                s.setUsageCount(s.getUsageCount() != null ? s.getUsageCount() + 1 : 1L);
                soundRepository.save(s);
            }
        } else if (musicTitle != null && !musicTitle.isBlank() && !"None".equalsIgnoreCase(musicTitle.trim())) {
            String trimmedTitle = musicTitle.trim();
            video.setMusicTitle(trimmedTitle);
            video.setMusicArtist(musicArtist != null && !musicArtist.isBlank() ? musicArtist.trim() : "@" + creator.getUsername());
            if (audioUrl != null && !audioUrl.isBlank()) {
                video.setAudioUrl(audioUrl.trim());
            }
            Optional<com.vilo.backend.entity.Sound> existingSound = soundRepository.findByTitleIgnoreCase(trimmedTitle);
            if (existingSound.isPresent()) {
                com.vilo.backend.entity.Sound s = existingSound.get();
                video.setSoundId(s.getId());
                if (video.getAudioUrl() == null || video.getAudioUrl().isBlank()) {
                    video.setAudioUrl(s.getAudioUrl());
                }
                s.setUsageCount(s.getUsageCount() != null ? s.getUsageCount() + 1 : 1L);
                soundRepository.save(s);
            } else if (audioUrl != null && !audioUrl.isBlank()) {
                com.vilo.backend.entity.Sound newSound = new com.vilo.backend.entity.Sound(
                        trimmedTitle,
                        creator.getId(),
                        creator.getUsername(),
                        audioUrl.trim(),
                        thumbnailUrl != null ? thumbnailUrl : videoUrl,
                        1L
                );
                newSound = soundRepository.save(newSound);
                video.setSoundId(newSound.getId());
            }
        } else {
            // Optional: User explicitly posted without music or selected None
            video.setSoundId(null);
            video.setMusicTitle(null);
            video.setMusicArtist(null);
            video.setAudioUrl(null);
        }

        // Normalize tags & extract hashtags from caption
        Set<String> cleanTagSet = new LinkedHashSet<>();
        if (tags != null) {
            for (String rawTag : tags) {
                if (rawTag != null) {
                    for (String part : rawTag.split("[,\\s]+")) {
                        String clean = part.trim().replaceAll("^#+", "");
                        if (!clean.isEmpty()) {
                            cleanTagSet.add(clean.toLowerCase());
                        }
                    }
                }
            }
        }
        if (effectiveCaption != null && !effectiveCaption.isBlank()) {
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("#([a-zA-Z0-9_]+)").matcher(effectiveCaption);
            while (matcher.find()) {
                String tagFromCaption = matcher.group(1).trim().toLowerCase();
                if (!tagFromCaption.isEmpty()) {
                    cleanTagSet.add(tagFromCaption);
                }
            }
        }

        for (String cleanTag : cleanTagSet) {
            video.getTags().add(new VideoTag(video, cleanTag));
            if (hashtagRepository != null) {
                try {
                    Hashtag hashtag = hashtagRepository.findByTagIgnoreCase(cleanTag)
                            .orElseGet(() -> new Hashtag(cleanTag, 0L, false));
                    hashtag.setUsageCount((hashtag.getUsageCount() != null ? hashtag.getUsageCount() : 0L) + 1);
                    hashtagRepository.save(hashtag);
                } catch (Exception ignored) {}
            }
        }

        return videoRepository.save(video);
    }

    @Transactional
    public Video createVideo(Long creatorId, String title, String description, String caption,
                            MultipartFile videoFile, String directPath,
MultipartFile thumbnailFile, String thumbnailPath,
                            Long soundId, MultipartFile audioFile,
                            String musicTitle, String musicArtist, String audioUrl,
                            List<String> tags) {
        return createVideo(creatorId, title, description, caption, videoFile, null, directPath, thumbnailFile, thumbnailPath, soundId, audioFile, musicTitle, musicArtist, audioUrl, tags);
    }

    @Transactional
    public Video createVideo(Long creatorId, String title, String description, String caption,
                            MultipartFile videoFile, String directPath,
                            MultipartFile thumbnailFile, String thumbnailPath,
                            String musicTitle, String musicArtist, String audioUrl,
                            List<String> tags) {
        return createVideo(creatorId, title, description, caption, videoFile, null, directPath, thumbnailFile, thumbnailPath, null, null, musicTitle, musicArtist, audioUrl, tags);
    }

    @Transactional
    public Video createVideo(Long creatorId, String title, String description, String caption,
                            MultipartFile videoFile, List<MultipartFile> mediaFiles, String directPath,
                            MultipartFile thumbnailFile, String thumbnailPath, List<String> tags) {
        return createVideo(creatorId, title, description, caption, videoFile, mediaFiles, directPath, thumbnailFile, thumbnailPath, null, null, null, null, null, tags);
    }

    @Transactional
    public Video createVideo(Long creatorId, String title, String description, String caption,
                            MultipartFile videoFile, String directPath,
                            MultipartFile thumbnailFile, String thumbnailPath, List<String> tags) {
        return createVideo(creatorId, title, description, caption, videoFile, null, directPath, thumbnailFile, thumbnailPath, null, null, null, null, null, tags);
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

        videoLikeRepository.deleteByVideoId(videoId);
        videoSaveRepository.deleteByVideoId(videoId);
        commentRepository.deleteByVideoId(videoId);

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

    @Transactional(readOnly = true)
    public List<VideoResponse> getLikedVideos(Long userId) {
        final User currentUser = userRepository.findById(userId).orElse(null);
        List<Video> videos = videoRepository.findLikedVideosByUserId(userId);
        return videos.stream()
                .map(v -> {
                    VideoResponse resp = VideoResponse.fromEntity(v, currentUser);
                    resp.setLiked(true);
                    resp.setSaved(isSavedBy(v.getId(), userId));
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getSavedVideos(Long userId) {
        final User currentUser = userRepository.findById(userId).orElse(null);
        List<Video> videos = videoRepository.findSavedVideosByUserId(userId);
        return videos.stream()
                .map(v -> {
                    VideoResponse resp = VideoResponse.fromEntity(v, currentUser);
                    resp.setLiked(isLikedBy(v.getId(), userId));
                    resp.setSaved(true);
                    return resp;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getVideosBySound(String musicName, User currentUser) {
        final User reloadedUser = (currentUser != null && currentUser.getId() != null)
                ? userRepository.findById(currentUser.getId()).orElse(currentUser)
                : null;
        Long currentUserId = reloadedUser != null ? reloadedUser.getId() : null;

        List<Video> videos = videoRepository.findByMusicTitleContainingIgnoreCase(musicName != null ? musicName.trim() : "");
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
}
