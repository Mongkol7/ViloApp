package com.vilo.backend.repository;

import com.vilo.backend.entity.Notification;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId, Pageable pageable);
    long countByRecipientIdAndReadAtIsNull(Long recipientId);
    Optional<Notification> findByIdAndRecipientId(Long id, Long recipientId);
    List<Notification> findByRecipientIdAndReadAtIsNull(Long recipientId);
}
