package com.vilo.backend.repository;

import com.vilo.backend.entity.Comment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {
    Page<Comment> findByVideoIdAndParentIdIsNullOrderByCreatedAtDesc(Long videoId, Pageable pageable);
    Page<Comment> findByParentIdOrderByCreatedAtAsc(Long parentId, Pageable pageable);
    long countByVideoId(Long videoId);
}
