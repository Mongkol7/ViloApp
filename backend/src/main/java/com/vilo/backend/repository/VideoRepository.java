package com.vilo.backend.repository;

import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface VideoRepository extends JpaRepository<Video, Long> {

    Page<Video> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<Video> findByCreatorInOrderByCreatedAtDesc(Collection<User> creators, Pageable pageable);

    List<Video> findByCreatorOrderByCreatedAtDesc(User creator);

    @Query("SELECT v FROM Video v WHERE v.creator.id IN :creatorIds ORDER BY v.createdAt DESC")
    Page<Video> findByCreatorIdIn(@Param("creatorIds") List<Long> creatorIds, Pageable pageable);
}
