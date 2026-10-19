package com.vilo.backend.repository;

import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface VideoRepository extends JpaRepository<Video, Long> {

    List<Video> findByCreatorInOrderByCreatedAtDesc(Collection<User> creators, Pageable pageable);

    List<Video> findAllByOrderByCreatedAtDesc(Pageable pageable);

    List<Video> findByCreatorOrderByCreatedAtDesc(User creator);
}
