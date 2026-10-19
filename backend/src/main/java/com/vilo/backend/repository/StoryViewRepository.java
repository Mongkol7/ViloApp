package com.vilo.backend.repository;

import com.vilo.backend.entity.StoryView;
import com.vilo.backend.entity.ThoughtStory;
import com.vilo.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StoryViewRepository extends JpaRepository<StoryView, Long> {

    boolean existsByStoryAndViewer(ThoughtStory story, User viewer);

    List<StoryView> findByStoryOrderByViewedAtDesc(ThoughtStory story);

    long countByStory(ThoughtStory story);

    void deleteByStory(ThoughtStory story);
}
