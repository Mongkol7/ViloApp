package com.vilo.backend.service;

import com.vilo.backend.entity.Comment;
import com.vilo.backend.entity.NotificationType;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.CommentRepository;
import com.vilo.backend.repository.UserRepository;
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
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public CommentService(CommentRepository commentRepository,
                          VideoRepository videoRepository,
                          UserRepository userRepository,
                          NotificationService notificationService) {
        this.commentRepository = commentRepository;
        this.videoRepository = videoRepository;
        this.userRepository = userRepository;
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

        // Send real-time notification to video creator
        try {
            User commenter = userRepository.findById(userId).orElse(null);
            User creator = video.getCreator();
            if (creator == null && video.getCreatorId() != null) {
                creator = userRepository.findById(video.getCreatorId()).orElse(null);
            }
            if (creator != null && commenter != null && !creator.getId().equals(commenter.getId())) {
                String snippet = content.length() > 50 ? content.substring(0, 47) + "..." : content;
                notificationService.sendNotification(
                        creator,
                        commenter,
                        NotificationType.COMMENT,
                        "New Comment",
                        commenter.getDisplayName() + " commented: \"" + snippet + "\"",
                        String.valueOf(videoId),
                        "VIDEO"
                );
            }

            // If it is a reply, also notify the parent comment author
            if (parentId != null) {
                final User finalCreator = creator;
                commentRepository.findById(parentId).ifPresent(parentComment -> {
                    if (!parentComment.getUserId().equals(userId) && (finalCreator == null || !parentComment.getUserId().equals(finalCreator.getId()))) {
                        userRepository.findById(parentComment.getUserId()).ifPresent(parentUser -> {
                            String snippet = content.length() > 50 ? content.substring(0, 47) + "..." : content;
                            notificationService.sendNotification(
                                    parentUser,
                                    commenter,
                                    NotificationType.COMMENT,
                                    "New Reply",
                                    commenter.getDisplayName() + " replied to your comment: \"" + snippet + "\"",
                                    String.valueOf(videoId),
                                    "VIDEO"
                            );
                        });
                    }
                });
            }
        } catch (Exception ignored) {}

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
