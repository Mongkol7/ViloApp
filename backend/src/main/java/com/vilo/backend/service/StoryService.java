package com.vilo.backend.service;

import com.vilo.backend.dto.CreateStoryRequest;
import com.vilo.backend.dto.StoryResponse;
import com.vilo.backend.dto.StoryViewerResponse;
import com.vilo.backend.entity.NotificationType;
import com.vilo.backend.entity.StoryView;
import com.vilo.backend.entity.ThoughtStory;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.StoryViewRepository;
import com.vilo.backend.repository.ThoughtStoryRepository;
import com.vilo.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;

@Service
public class StoryService {

    private static final Logger log = LoggerFactory.getLogger(StoryService.class);

    private final ThoughtStoryRepository storyRepository;
    private final StoryViewRepository storyViewRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public StoryService(
            ThoughtStoryRepository storyRepository,
            StoryViewRepository storyViewRepository,
            UserRepository userRepository,
            NotificationService notificationService
    ) {
        this.storyRepository = storyRepository;
        this.storyViewRepository = storyViewRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<StoryResponse> getActiveStories(User currentUser) {
        Instant now = Instant.now();
        User managedUser = userRepository.findById(currentUser.getId()).orElse(currentUser);
        Set<User> following = managedUser.getFollowing();

        List<ThoughtStory> stories;
        if (following != null && !following.isEmpty()) {
            stories = storyRepository.findActiveForUsersAndSelf(following, managedUser, now);
        } else {
            stories = storyRepository.findAllActive(now);
        }

        return stories.stream()
                .map(s -> mapToResponse(s, managedUser))
                .toList();
    }

    @Transactional
    public StoryResponse createStory(User currentUser, CreateStoryRequest request) {
        int durationHours = request.getExpiresInHours() != null && request.getExpiresInHours() > 0
                ? request.getExpiresInHours()
                : 24;

        Instant expiresAt = Instant.now().plus(Duration.ofHours(durationHours));

        ThoughtStory story = ThoughtStory.builder()
                .user(currentUser)
                .message(request.getMessage().trim())
                .musicTrackId(request.getMusicTrackId())
                .musicTitle(request.getMusicTitle())
                .musicArtist(request.getMusicArtist())
                .musicAlbumArt(request.getMusicAlbumArt())
                .musicPreviewUrl(request.getMusicPreviewUrl())
                .musicDuration(request.getMusicDuration())
                .backgroundGradient(request.getBackgroundGradient())
                .viewCount(0)
                .expiresAt(expiresAt)
                .build();

        ThoughtStory saved = storyRepository.save(story);
        return mapToResponse(saved, currentUser);
    }

    @Transactional
    public StoryResponse recordView(User currentUser, Long storyId) {
        ThoughtStory story = storyRepository.findById(storyId)
                .orElseThrow(() -> new ResourceNotFoundException("Story not found with id: " + storyId));

        if (story.getExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("This story has already expired");
        }

        boolean alreadyViewed = storyViewRepository.existsByStoryAndViewer(story, currentUser);
        if (!alreadyViewed) {
            StoryView view = StoryView.builder()
                    .story(story)
                    .viewer(currentUser)
                    .build();
            storyViewRepository.save(view);

            story.setViewCount(story.getViewCount() + 1);
            storyRepository.save(story);

            // Notify owner if viewed by another user
            if (!story.getUser().getId().equals(currentUser.getId())) {
                notificationService.sendNotification(
                        story.getUser(),
                        currentUser,
                        NotificationType.STORY_VIEW,
                        "New Story View",
                        currentUser.getDisplayName() + " viewed your 24h thought",
                        String.valueOf(story.getId()),
                        "STORY"
                );
            }
        }

        return mapToResponse(story, currentUser);
    }

    @Transactional(readOnly = true)
    public List<StoryViewerResponse> getStoryViewers(User currentUser, Long storyId) {
        ThoughtStory story = storyRepository.findById(storyId)
                .orElseThrow(() -> new ResourceNotFoundException("Story not found with id: " + storyId));

        return storyViewRepository.findByStoryOrderByViewedAtDesc(story)
                .stream()
                .map(v -> StoryViewerResponse.builder()
                        .id(v.getId())
                        .userId(v.getViewer().getId())
                        .username(v.getViewer().getUsername())
                        .displayName(v.getViewer().getDisplayName())
                        .avatarUrl(v.getViewer().getAvatarUrl())
                        .isVerified(v.getViewer().getIsVerified())
                        .viewedAt(v.getViewedAt())
                        .build())
                .toList();
    }

    @Transactional
    public void deleteStory(User currentUser, Long storyId) {
        ThoughtStory story = storyRepository.findById(storyId)
                .orElseThrow(() -> new ResourceNotFoundException("Story not found with id: " + storyId));

        if (!story.getUser().getId().equals(currentUser.getId())) {
            throw new BadRequestException("You can only delete your own stories");
        }

        storyViewRepository.deleteByStory(story);
        storyRepository.delete(story);
    }

    public StoryResponse mapToResponse(ThoughtStory story, User currentUser) {
        boolean isMe = story.getUser().getId().equals(currentUser.getId());
        boolean viewed = isMe || storyViewRepository.existsByStoryAndViewer(story, currentUser);

        return StoryResponse.builder()
                .id(story.getId())
                .userId(story.getUser().getId())
                .username(story.getUser().getUsername())
                .displayName(story.getUser().getDisplayName())
                .avatarUrl(story.getUser().getAvatarUrl())
                .isVerified(story.getUser().getIsVerified())
                .message(story.getMessage())
                .musicTrackId(story.getMusicTrackId())
                .musicTitle(story.getMusicTitle())
                .musicArtist(story.getMusicArtist())
                .musicAlbumArt(story.getMusicAlbumArt())
                .musicPreviewUrl(story.getMusicPreviewUrl())
                .musicDuration(story.getMusicDuration())
                .backgroundGradient(story.getBackgroundGradient())
                .viewCount(story.getViewCount())
                .expiresAt(story.getExpiresAt())
                .createdAt(story.getCreatedAt())
                .isViewedByMe(viewed)
                .isMyStory(isMe)
                .build();
    }
}
