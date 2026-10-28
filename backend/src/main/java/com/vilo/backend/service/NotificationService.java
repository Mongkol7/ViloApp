package com.vilo.backend.service;

import com.vilo.backend.dto.NotificationResponse;
import com.vilo.backend.entity.Notification;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.NotificationRepository;
import com.vilo.backend.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NotificationService {
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationService(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public void createLike(Long actorId, Long recipientId, Long videoId) {
        create(actorId, recipientId, "LIKE", videoId, null, null, null);
    }

    @Transactional
    public void createComment(Long actorId, Long videoOwnerId, Long parentAuthorId,
                              Long videoId, Long commentId, String excerpt) {
        create(actorId, videoOwnerId, "COMMENT", videoId, commentId, null, excerpt);
        if (parentAuthorId != null && !parentAuthorId.equals(videoOwnerId)) {
            create(actorId, parentAuthorId, "REPLY", videoId, commentId, null, excerpt);
        }
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void createFollow(Long actorId, Long recipientId) {
        create(actorId, recipientId, "FOLLOW", null, null, recipientId, null);
    }

    private void create(Long actorId, Long recipientId, String type, Long videoId,
                        Long commentId, Long targetUserId, String excerpt) {
        if (actorId == null || recipientId == null || actorId.equals(recipientId)) return;
        String safeExcerpt = excerpt == null ? null : excerpt.trim();
        if (safeExcerpt != null && safeExcerpt.length() > 240) {
            safeExcerpt = safeExcerpt.substring(0, 240);
        }
        Notification notification = new Notification(
                recipientId, actorId, type, videoId, commentId, targetUserId, safeExcerpt);
        // Keep this explicit as well as @PrePersist/@CreationTimestamp so the
        // NOT NULL database column is safe with every Hibernate insert path.
        if (notification.getCreatedAt() == null) {
            notification.setCreatedAt(Instant.now());
        }
        notificationRepository.save(notification);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getForUser(User currentUser, int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 100));
        List<NotificationResponse> items = notificationRepository
                .findByRecipientIdOrderByCreatedAtDesc(currentUser.getId(), PageRequest.of(0, safeLimit))
                .stream()
                .map(this::toResponse)
                .toList();
        Map<String, Object> result = new HashMap<>();
        result.put("notifications", items);
        result.put("unreadCount", notificationRepository.countByRecipientIdAndReadAtIsNull(currentUser.getId()));
        return result;
    }

    @Transactional
    public NotificationResponse markRead(User currentUser, Long notificationId) {
        Notification notification = notificationRepository.findByIdAndRecipientId(notificationId, currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
        if (notification.getReadAt() == null) notification.setReadAt(Instant.now());
        return toResponse(notificationRepository.save(notification));
    }

    @Transactional
    public void markAllRead(User currentUser) {
        List<Notification> unread = notificationRepository.findByRecipientIdAndReadAtIsNull(currentUser.getId());
        Instant now = Instant.now();
        unread.forEach(notification -> notification.setReadAt(now));
        notificationRepository.saveAll(unread);
    }

    private NotificationResponse toResponse(Notification notification) {
        User actor = userRepository.findById(notification.getActorId()).orElse(null);
        return NotificationResponse.fromEntity(notification, actor);
    }
}
