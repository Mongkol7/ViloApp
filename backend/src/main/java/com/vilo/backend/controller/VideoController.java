package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.CommentResponse;
import com.vilo.backend.dto.CreateCommentRequest;
import com.vilo.backend.dto.VideoResponse;
import com.vilo.backend.entity.Comment;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.VideoTag;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.service.CommentService;
import com.vilo.backend.service.VideoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;

@RestController
@RequestMapping("/api/v1/videos")
@Tag(name = "Video Feed & Engine", description = "Endpoints for home video feeds (For You and Following), creator videos, comments, and interactions")
public class VideoController {

    private final VideoService videoService;
    private final CommentService commentService;
    private final UserRepository userRepository;

    public VideoController(VideoService videoService,
                           CommentService commentService,
                           UserRepository userRepository) {
        this.videoService = videoService;
        this.commentService = commentService;
        this.userRepository = userRepository;
    }

    /**
     * GET /api/v1/videos/feed
     * Paginated video feeds (foryou / following).
     */
    @GetMapping("/feed")
    @Operation(summary = "Get video feed", description = "Retrieves paginated video feed filtered by foryou / following")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFeed(
            @Parameter(description = "Feed type: foryou or following")
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "foryou") String type,
            @AuthenticationPrincipal User currentUser
    ) {
        List<Long> followingIds = null;
        Long currentUserId = currentUser != null ? currentUser.getId() : null;

        if ("following".equalsIgnoreCase(type) && currentUser != null && currentUser.getFollowing() != null) {
            followingIds = currentUser.getFollowing().stream()
                    .map(User::getId)
                    .toList();
        }

        Pageable pageable = PageRequest.of(page, size);
        Page<Video> videoPage = videoService.getFeed(type, followingIds, pageable);

        List<VideoResponse> responses = videoPage.getContent().stream()
                .map(video -> mapToVideoResponse(video, currentUserId))
                .toList();

        Map<String, Object> data = new HashMap<>();
        data.put("videos", responses);
        data.put("currentPage", videoPage.getNumber());
        data.put("totalItems", videoPage.getTotalElements());
        data.put("totalPages", videoPage.getTotalPages());
        data.put("hasNext", videoPage.hasNext());

        return ResponseEntity.ok(ApiResponse.ok("Feed retrieved successfully", data));
    }

    /**
     * GET /api/v1/videos/user/{identifier}
     * Retrieves all public videos posted by a specific creator (by ID or username).
     */
    @GetMapping("/user/{identifier}")
    @Operation(summary = "Get creator videos", description = "Retrieves all public videos posted by a specific user (by ID or username)")
    public ResponseEntity<ApiResponse<List<VideoResponse>>> getUserVideos(
            @PathVariable String identifier,
            @AuthenticationPrincipal User currentUser
    ) {
        List<VideoResponse> videos = videoService.getUserVideos(identifier, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("User videos fetched successfully", videos));
    }

    /**
     * GET /api/v1/videos/{id}
     * Single video details with creator profile and interaction flags.
     */
    @GetMapping("/{id}")
    @Operation(summary = "Get video by ID")
    public ResponseEntity<ApiResponse<VideoResponse>> getVideoById(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        Long currentUserId = currentUser != null ? currentUser.getId() : null;
        Video video = videoService.getVideoById(id);
        VideoResponse response = mapToVideoResponse(video, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Video retrieved successfully", response));
    }

    /**
     * POST /api/v1/videos/upload
     * Supports both multipart file upload AND direct videoPath/videoUrl reference.
     */
    @PostMapping(value = "/upload")
    @Operation(summary = "Upload video or photo post")
    public ResponseEntity<ApiResponse<VideoResponse>> uploadVideo(
            @RequestParam(value = "video", required = false) MultipartFile video,
            @RequestParam(value = "videoFile", required = false) MultipartFile videoFile,
            @RequestParam(value = "videoPath", required = false) String videoPath,
            @RequestParam(value = "videoUrl", required = false) String videoUrl,
            @RequestParam(value = "thumbnail", required = false) MultipartFile thumbnail,
            @RequestParam(value = "thumbnailFile", required = false) MultipartFile thumbnailFile,
            @RequestParam(value = "thumbnailPath", required = false) String thumbnailPath,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "caption", required = false) String caption,
            @RequestParam(value = "tags", required = false) List<String> tags,
            @AuthenticationPrincipal User currentUser
    ) {
        if (currentUser == null) {
            throw new AccessDeniedException("Full authentication is required to upload videos");
        }

        MultipartFile effectiveVideoFile = (video != null && !video.isEmpty()) ? video : videoFile;
        MultipartFile effectiveThumbnailFile = (thumbnail != null && !thumbnail.isEmpty()) ? thumbnail : thumbnailFile;

        String directPath = videoPath != null && !videoPath.isBlank() 
                ? videoPath.trim() 
                : (videoUrl != null && !videoUrl.isBlank() ? videoUrl.trim() : null);

        if ((effectiveVideoFile == null || effectiveVideoFile.isEmpty()) && (directPath == null || directPath.isBlank())) {
            throw new IllegalArgumentException("Either video/photo file or video/photo path must be provided");
        }

        String effectiveCaption = (caption != null && !caption.isBlank())
                ? caption.trim()
                : ((title != null ? title : "") + (description != null && !description.isBlank() ? " " + description : "")).trim();

        Video savedVideo = videoService.createVideo(
                currentUser.getId(),
                title,
                description,
                effectiveCaption,
                effectiveVideoFile,
                directPath,
                effectiveThumbnailFile,
                thumbnailPath,
                tags
        );
        VideoResponse response = mapToVideoResponse(savedVideo, currentUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Video uploaded successfully", response));
    }

    /**
     * DELETE /api/v1/videos/{id}
     * Delete video (owner only).
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "Delete video")
    public ResponseEntity<ApiResponse<Void>> deleteVideo(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        if (currentUser == null) {
            throw new AccessDeniedException("Full authentication is required to delete videos");
        }

        videoService.deleteVideo(id, currentUser.getId());
        return ResponseEntity.ok(ApiResponse.ok("Video deleted successfully", null));
    }

    /**
     * POST /api/v1/videos/{id}/like
     * Toggle like for the authenticated user.
     */
    @PostMapping("/{id}/like")
    @Operation(summary = "Toggle like")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleLike(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required to like videos");
        }

        boolean isLiked = videoService.toggleLike(id, currentUser.getId());
        Video video = videoService.getVideoById(id);

        Map<String, Object> data = Map.of(
                "isLiked", isLiked,
                "likeCount", video.getLikeCount()
        );
        String message = isLiked ? "Video liked" : "Video unliked";
        return ResponseEntity.ok(ApiResponse.ok(message, data));
    }

    /**
     * DELETE /api/v1/videos/{id}/like
     * Remove like if liked.
     */
    @DeleteMapping("/{id}/like")
    @Operation(summary = "Remove like")
    public ResponseEntity<ApiResponse<Map<String, Object>>> removeLike(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required to unlike videos");
        }

        boolean currentlyLiked = videoService.isLikedBy(id, currentUser.getId());
        if (currentlyLiked) {
            videoService.toggleLike(id, currentUser.getId());
        }

        Video video = videoService.getVideoById(id);
        Map<String, Object> data = Map.of(
                "isLiked", false,
                "likeCount", video.getLikeCount()
        );
        return ResponseEntity.ok(ApiResponse.ok("Video unliked", data));
    }

    /**
     * POST /api/v1/videos/{id}/save
     * Toggle bookmark/save for the authenticated user.
     */
    @PostMapping("/{id}/save")
    @Operation(summary = "Toggle bookmark/save")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleSave(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required to save videos");
        }

        boolean isSaved = videoService.toggleSave(id, currentUser.getId());
        Video video = videoService.getVideoById(id);

        Map<String, Object> data = Map.of(
                "isSaved", isSaved,
                "saveCount", video.getSaveCount()
        );
        String message = isSaved ? "Video saved" : "Video unsaved";
        return ResponseEntity.ok(ApiResponse.ok(message, data));
    }

    /**
     * DELETE /api/v1/videos/{id}/save
     * Remove bookmark/save if saved.
     */
    @DeleteMapping("/{id}/save")
    @Operation(summary = "Remove bookmark/save")
    public ResponseEntity<ApiResponse<Map<String, Object>>> removeSave(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required to unsave videos");
        }

        boolean currentlySaved = videoService.isSavedBy(id, currentUser.getId());
        if (currentlySaved) {
            videoService.toggleSave(id, currentUser.getId());
        }

        Video video = videoService.getVideoById(id);
        Map<String, Object> data = Map.of(
                "isSaved", false,
                "saveCount", video.getSaveCount()
        );
        return ResponseEntity.ok(ApiResponse.ok("Video unsaved", data));
    }

    /**
     * GET /api/v1/videos/{id}/comments
     * Paginated root comments with nested replies.
     */
    @GetMapping("/{id}/comments")
    @Operation(summary = "Get video comments")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getComments(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Comment> commentPage = commentService.getCommentsForVideo(id, pageable);

        List<CommentResponse> responses = commentPage.getContent().stream()
                .map(this::mapToCommentResponseWithReplies)
                .toList();

        Map<String, Object> data = new HashMap<>();
        data.put("comments", responses);
        data.put("currentPage", commentPage.getNumber());
        data.put("totalItems", commentPage.getTotalElements());
        data.put("totalPages", commentPage.getTotalPages());
        data.put("hasNext", commentPage.hasNext());

        return ResponseEntity.ok(ApiResponse.ok("Comments retrieved successfully", data));
    }

    /**
     * POST /api/v1/videos/{id}/comments
     * Post a new comment or reply.
     */
    @PostMapping("/{id}/comments")
    @Operation(summary = "Post comment or reply")
    public ResponseEntity<ApiResponse<CommentResponse>> postComment(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody CreateCommentRequest request
    ) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required to post comments");
        }

        Comment savedComment = commentService.addComment(
                id,
                currentUser.getId(),
                request.getParentId(),
                request.getContent()
        );

        CommentResponse response = CommentResponse.builder()
                .id(savedComment.getId())
                .videoId(savedComment.getVideoId())
                .userId(currentUser.getId())
                .username(currentUser.getUsername())
                .displayName(currentUser.getDisplayName() != null ? currentUser.getDisplayName() : currentUser.getUsername())
                .avatarUrl(currentUser.getAvatarUrl())
                .parentId(savedComment.getParentId())
                .content(savedComment.getContent())
                .createdAt(savedComment.getCreatedAt())
                .replies(new ArrayList<>())
                .build();

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Comment posted successfully", response));
    }

    /**
     * POST /api/v1/videos/{id}/view
     * Increment view count asynchronously.
     */
    @PostMapping("/{id}/view")
    @Operation(summary = "Increment view count")
    public ResponseEntity<ApiResponse<Map<String, Object>>> recordView(@PathVariable Long id) {
        videoService.incrementViewCount(id);
        Video video = videoService.getVideoById(id);
        return ResponseEntity.ok(ApiResponse.ok("View count recorded", Map.of("viewCount", video.getViewCount())));
    }

    // Helper mapping methods
    private VideoResponse mapToVideoResponse(Video video, Long currentUserId) {
        User creator = video.getCreator();
        if (creator == null && video.getCreatorId() != null) {
            creator = userRepository.findById(video.getCreatorId()).orElse(null);
        }

        String username = creator != null ? creator.getUsername() : "creator_" + video.getCreatorId();
        String displayName = creator != null && creator.getDisplayName() != null
                ? creator.getDisplayName()
                : username;
        String avatarUrl = creator != null ? creator.getAvatarUrl() : null;
        boolean isVerified = creator != null && Boolean.TRUE.equals(creator.getIsVerified());

        List<String> tags = new ArrayList<>();
        if (video.getTags() != null) {
            for (VideoTag tag : video.getTags()) {
                tags.add(tag.getTagName());
            }
        }

        boolean isLiked = currentUserId != null && videoService.isLikedBy(video.getId(), currentUserId);
        boolean isSaved = currentUserId != null && videoService.isSavedBy(video.getId(), currentUserId);
        boolean isMe = currentUserId != null && creator != null && currentUserId.equals(creator.getId());
        boolean isFollowing = false;
        if (currentUserId != null && creator != null) {
            User current = userRepository.findById(currentUserId).orElse(null);
            if (current != null && current.getFollowing() != null) {
                final Long targetId = creator.getId();
                isFollowing = current.getFollowing().stream().anyMatch(f -> f.getId().equals(targetId));
            }
        }

        return VideoResponse.builder()
                .id(video.getId())
                .creatorId(video.getCreatorId())
                .username(username.startsWith("@") ? username : "@" + username)
                .displayName(displayName)
                .avatarUrl(avatarUrl)
                .isVerified(isVerified)
                .title(video.getTitle())
                .description(video.getDescription())
                .caption(video.getCaption())
                .videoUrl(video.getVideoUrl())
                .thumbnailUrl(video.getThumbnailUrl())
                .musicTitle(video.getMusicTitle() != null ? video.getMusicTitle() : "Original Sound - " + displayName)
                .viewCount(video.getViewCount())
                .likeCount(video.getLikeCount())
                .commentCount(video.getCommentCount())
                .saveCount(video.getSaveCount())
                .isLiked(isLiked)
                .isSaved(isSaved)
                .isFollowing(isFollowing)
                .isMe(isMe)
                .tags(tags)
                .createdAt(video.getCreatedAt())
                .build();
    }

    private CommentResponse mapToCommentResponseWithReplies(Comment comment) {
        User author = userRepository.findById(comment.getUserId()).orElse(null);

        String username = author != null ? author.getUsername() : "user_" + comment.getUserId();
        String displayName = author != null && author.getDisplayName() != null
                ? author.getDisplayName()
                : username;
        String avatarUrl = author != null ? author.getAvatarUrl() : null;

        Page<Comment> replyPage = commentService.getRepliesForComment(comment.getId(), PageRequest.of(0, 50));
        List<CommentResponse> replies = replyPage.getContent().stream()
                .map(this::mapToCommentResponseSingle)
                .toList();

        return CommentResponse.builder()
                .id(comment.getId())
                .videoId(comment.getVideoId())
                .userId(comment.getUserId())
                .username(username)
                .displayName(displayName)
                .avatarUrl(avatarUrl)
                .parentId(comment.getParentId())
                .content(comment.getContent())
                .createdAt(comment.getCreatedAt())
                .replies(replies)
                .build();
    }

    private CommentResponse mapToCommentResponseSingle(Comment reply) {
        User author = userRepository.findById(reply.getUserId()).orElse(null);

        String username = author != null ? author.getUsername() : "user_" + reply.getUserId();
        String displayName = author != null && author.getDisplayName() != null
                ? author.getDisplayName()
                : username;
        String avatarUrl = author != null ? author.getAvatarUrl() : null;

        return CommentResponse.builder()
                .id(reply.getId())
                .videoId(reply.getVideoId())
                .userId(reply.getUserId())
                .username(username)
                .displayName(displayName)
                .avatarUrl(avatarUrl)
                .parentId(reply.getParentId())
                .content(reply.getContent())
                .createdAt(reply.getCreatedAt())
                .replies(new ArrayList<>())
                .build();
    }
}
