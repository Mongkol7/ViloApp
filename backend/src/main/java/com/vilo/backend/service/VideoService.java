package com.vilo.backend.service;

import com.vilo.backend.dto.VideoResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.repository.VideoRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class VideoService {

    private final VideoRepository videoRepository;
    private final UserRepository userRepository;

    public VideoService(VideoRepository videoRepository, UserRepository userRepository) {
        this.videoRepository = videoRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<VideoResponse> getVideoFeed(String type, User currentUser, int page, int size) {
        final User reloadedUser = (currentUser != null && currentUser.getId() != null)
                ? userRepository.findById(currentUser.getId()).orElse(currentUser)
                : null;

        String feedType = type != null ? type.toUpperCase() : "FOR_YOU";
        List<Video> videos;

        if ("FOLLOWING".equals(feedType)) {
            if (reloadedUser != null && reloadedUser.getFollowing() != null && !reloadedUser.getFollowing().isEmpty()) {
                videos = videoRepository.findByCreatorInOrderByCreatedAtDesc(
                        reloadedUser.getFollowing(),
                        PageRequest.of(page, size)
                );
            } else {
                // If not following anyone yet, provide featured creator videos so screen isn't empty
                videos = videoRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(page, size));
            }
        } else {
            // FOR_YOU
            videos = videoRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(page, size));
        }

        return videos.stream()
                .map(v -> VideoResponse.fromEntity(v, reloadedUser))
                .collect(Collectors.toList());
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
            Long id = Long.parseLong(identifier);
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
        return videos.stream()
                .map(v -> VideoResponse.fromEntity(v, reloadedUser))
                .collect(Collectors.toList());
    }
}
