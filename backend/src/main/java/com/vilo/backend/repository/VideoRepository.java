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

    List<Video> findByCreatorIdOrderByCreatedAtDesc(Long creatorId);

    List<Video> findByCreatorUsernameOrderByCreatedAtDesc(String username);

    List<Video> findBySoundIdOrderByCreatedAtDesc(Long soundId);

    long countBySoundId(Long soundId);

    @Query("SELECT v FROM Video v WHERE v.creator.id IN :creatorIds ORDER BY v.createdAt DESC")
    Page<Video> findByCreatorIdIn(@Param("creatorIds") List<Long> creatorIds, Pageable pageable);

    @Query("SELECT v FROM Video v JOIN VideoLike vl ON v.id = vl.videoId WHERE vl.userId = :userId ORDER BY vl.createdAt DESC")
    List<Video> findLikedVideosByUserId(@Param("userId") Long userId);

    @Query("SELECT v FROM Video v JOIN VideoSave vs ON v.id = vs.videoId WHERE vs.userId = :userId ORDER BY vs.createdAt DESC")
    List<Video> findSavedVideosByUserId(@Param("userId") Long userId);

    @Query("SELECT v FROM Video v WHERE LOWER(v.musicTitle) LIKE LOWER(CONCAT('%', :musicTitle, '%')) ORDER BY v.createdAt DESC")
    List<Video> findByMusicTitleContainingIgnoreCase(@Param("musicTitle") String musicTitle);

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @Query("UPDATE Video v SET v.soundId = null WHERE v.soundId = :soundId")
    void clearSoundId(@Param("soundId") Long soundId);

    @Query("""
        SELECT DISTINCT v FROM Video v
        LEFT JOIN v.tags t
        LEFT JOIN v.creator c
        WHERE LOWER(COALESCE(v.title, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
           OR LOWER(COALESCE(v.caption, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
           OR LOWER(COALESCE(v.description, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
           OR LOWER(COALESCE(t.tagName, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
           OR LOWER(COALESCE(c.username, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
           OR LOWER(COALESCE(c.displayName, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))
        ORDER BY v.createdAt DESC
    """)
    List<Video> searchVideos(@Param("keyword") String keyword, Pageable pageable);

    @Query("""
        SELECT DISTINCT v FROM Video v
        JOIN v.tags t
        WHERE LOWER(t.tagName) = LOWER(:tagName)
           OR LOWER(v.caption) LIKE LOWER(CONCAT('%#', :tagName, '%'))
        ORDER BY v.createdAt DESC
    """)
    List<Video> findByTagName(@Param("tagName") String tagName, Pageable pageable);
}
