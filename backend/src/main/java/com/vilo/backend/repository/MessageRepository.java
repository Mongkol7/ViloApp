package com.vilo.backend.repository;

import com.vilo.backend.entity.Conversation;
import com.vilo.backend.entity.Message;
import com.vilo.backend.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

    Page<Message> findByConversationOrderByCreatedAtDesc(Conversation conversation, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.conversation = :conv AND " +
           "((m.sender = :user AND m.deletedBySender = false) OR " +
           " (m.recipient = :user AND m.deletedByRecipient = false)) " +
           "ORDER BY m.createdAt DESC")
    Page<Message> findVisibleMessagesForUser(
            @Param("conv") Conversation conv,
            @Param("user") User user,
            Pageable pageable
    );

    List<Message> findByConversation(Conversation conversation);

    List<Message> findTop50ByConversationOrderByCreatedAtAsc(Conversation conversation);

    long countByConversationAndRecipientAndIsReadFalse(Conversation conversation, User recipient);

    List<Message> findByConversationAndRecipientAndIsReadFalse(Conversation conversation, User recipient);

    @Modifying
    @Query("UPDATE Message m SET m.isRead = true WHERE m.conversation = :conversation AND m.recipient = :recipient AND m.isRead = false")
    void markConversationMessagesAsRead(@Param("conversation") Conversation conversation, @Param("recipient") User recipient);

    @Modifying
    @Query("DELETE FROM Message m WHERE m.conversation = :conversation")
    void deleteByConversation(@Param("conversation") Conversation conversation);

    Optional<Message> findTopByConversationOrderByCreatedAtDesc(Conversation conversation);
}
