package com.vilo.backend.service;

import com.vilo.backend.dto.NotificationResponse;
import com.vilo.backend.entity.Notification;
import com.vilo.backend.entity.NotificationType;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.NotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationService(NotificationRepository notificationRepository, SimpMessagingTemplate messagingTemplate) {
        this.notificationRepository = notificationRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getNotifications(User currentUser) {
        List<Notification> raw = notificationRepository.findByRecipientOrderByCreatedAtDesc(currentUser);
        java.util.Map<String, Notification> uniqueMap = new java.util.LinkedHashMap<>();
        for (Notification n : raw) {
            String actorKey = n.getActor() != null ? String.valueOf(n.getActor().getId()) : (n.getEntityId() != null ? n.getEntityId() : "system");
            String key = n.getType() + "_" + actorKey;
            uniqueMap.putIfAbsent(key, n);
        }
        return uniqueMap.values().stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional
    public NotificationResponse markAsRead(User currentUser, Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found with id: " + notificationId));

        if (!notification.getRecipient().getId().equals(currentUser.getId())) {
            throw new ResourceNotFoundException("Notification not found with id: " + notificationId);
        }

        notification.setIsRead(true);
        Notification updated = notificationRepository.save(notification);
        return mapToResponse(updated);
    }

    @Transactional
    public void markAllAsRead(User currentUser) {
        notificationRepository.markAllAsRead(currentUser);
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(User currentUser) {
        return notificationRepository.countByRecipientAndIsReadFalse(currentUser);
    }

    @Transactional
    public Notification sendNotification(
            User recipient,
            User actor,
            NotificationType type,
            String title,
            String body,
            String entityId,
            String entityType
    ) {
        // Do not notify self
        if (actor != null && recipient.getId().equals(actor.getId())) {
            return null;
        }

        Notification notification;
        List<Notification> existing = (actor != null)
                ? notificationRepository.findByRecipientAndActorAndType(recipient, actor, type)
                : java.util.Collections.emptyList();

        if (!existing.isEmpty()) {
            notification = existing.get(0);
            notification.setTitle(title);
            notification.setBody(body);
            notification.setEntityId(entityId);
            notification.setEntityType(entityType);
            notification.setIsRead(false);
        } else {
            notification = Notification.builder()
                    .recipient(recipient)
                    .actor(actor)
                    .type(type)
                    .title(title)
                    .body(body)
                    .entityId(entityId)
                    .entityType(entityType)
                    .isRead(false)
                    .build();
        }

        Notification saved = notificationRepository.save(notification);
        NotificationResponse response = mapToResponse(saved);

        // Real-time delivery to user queue
        try {
            messagingTemplate.convertAndSendToUser(
                    recipient.getUsername(),
                    "/queue/notifications",
                    response
            );
        } catch (Exception ex) {
            log.warn("Failed to push real-time notification to user {}: {}", recipient.getUsername(), ex.getMessage());
        }

        return saved;
    }

    public NotificationResponse mapToResponse(Notification notification) {
        NotificationResponse.Builder builder = NotificationResponse.builder()
                .id(notification.getId())
                .type(notification.getType())
                .title(notification.getTitle())
                .body(notification.getBody())
                .entityId(notification.getEntityId())
                .entityType(notification.getEntityType())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt());

        if (notification.getActor() != null) {
            builder.actorId(notification.getActor().getId())
                    .actorUsername(notification.getActor().getUsername())
                    .actorDisplayName(notification.getActor().getDisplayName())
                    .actorAvatarUrl(notification.getActor().getAvatarUrl());
        }

        return builder.build();
    }
}
