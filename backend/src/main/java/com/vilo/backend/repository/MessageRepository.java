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

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

    Page<Message> findByConversationOrderByCreatedAtDesc(Conversation conversation, Pageable pageable);

    List<Message> findTop50ByConversationOrderByCreatedAtAsc(Conversation conversation);

    long countByConversationAndRecipientAndIsReadFalse(Conversation conversation, User recipient);

    @Modifying
    @Query("UPDATE Message m SET m.isRead = true WHERE m.conversation = :conversation AND m.recipient = :recipient AND m.isRead = false")
    void markConversationMessagesAsRead(@Param("conversation") Conversation conversation, @Param("recipient") User recipient);
}
