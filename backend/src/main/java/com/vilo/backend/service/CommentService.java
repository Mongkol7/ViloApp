package com.vilo.backend.service;

import com.vilo.backend.entity.Comment;
import com.vilo.backend.entity.Video;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.CommentRepository;
import com.vilo.backend.repository.VideoRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CommentService {

    private final CommentRepository commentRepository;
    private final VideoRepository videoRepository;
    private final NotificationService notificationService;

    public CommentService(CommentRepository commentRepository, VideoRepository videoRepository,
                          NotificationService notificationService) {
        this.commentRepository = commentRepository;
        this.videoRepository = videoRepository;
        this.notificationService = notificationService;
    }

    public Page<Comment> getCommentsForVideo(Long videoId, Pageable pageable) {
        return commentRepository.findByVideoIdAndParentIdIsNullOrderByCreatedAtDesc(videoId, pageable);
    }

    public Page<Comment> getRepliesForComment(Long parentId, Pageable pageable) {
        return commentRepository.findByParentIdOrderByCreatedAtAsc(parentId, pageable);
    }

    @Transactional
    public Comment addComment(Long videoId, Long userId, Long parentId, String content) {
        Video video = videoRepository.findById(videoId)
                .orElseThrow(() -> new ResourceNotFoundException("Video not found with id: " + videoId));

        Comment comment = new Comment(videoId, userId, parentId, content);
        Comment savedComment = commentRepository.save(comment);

        // Update comment count on video
        video.setCommentCount(video.getCommentCount() + 1);
        videoRepository.save(video);

        Long parentAuthorId = parentId == null
                ? null
                : commentRepository.findById(parentId).map(Comment::getUserId).orElse(null);
        Long videoOwnerId = video.getCreator() != null ? video.getCreator().getId() : null;
        notificationService.createComment(
                userId, videoOwnerId, parentAuthorId, videoId, savedComment.getId(), content);

        return savedComment;
    }

    @Transactional
    public void deleteComment(Long videoId, Long commentId, Long userId) {
        Video video = videoRepository.findById(videoId)
                .orElseThrow(() -> new ResourceNotFoundException("Video not found with id: " + videoId));

        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found with id: " + commentId));

        if (!comment.getVideoId().equals(videoId)) {
            throw new IllegalArgumentException("Comment does not belong to the specified video");
        }

        boolean isAuthor = comment.getUserId().equals(userId);
        boolean isVideoOwner = video.getCreatorId() != null && video.getCreatorId().equals(userId);

        if (!isAuthor && !isVideoOwner) {
            throw new AccessDeniedException("Unauthorized: You can only delete your own comments or comments on your video.");
        }

        commentRepository.delete(comment);

        long currentCount = video.getCommentCount() != null ? video.getCommentCount() : 0L;
        video.setCommentCount(Math.max(0L, currentCount - 1));
        videoRepository.save(video);
    }
}
