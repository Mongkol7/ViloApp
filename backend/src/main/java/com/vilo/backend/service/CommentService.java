package com.vilo.backend.service;

import com.vilo.backend.entity.Comment;
import com.vilo.backend.entity.Video;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.CommentRepository;
import com.vilo.backend.repository.VideoRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CommentService {

    private final CommentRepository commentRepository;
    private final VideoRepository videoRepository;

    public CommentService(CommentRepository commentRepository, VideoRepository videoRepository) {
        this.commentRepository = commentRepository;
        this.videoRepository = videoRepository;
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

        return savedComment;
    }
}
