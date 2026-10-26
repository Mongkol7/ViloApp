package com.vilo.backend.service;

import com.vilo.backend.dto.ConversationResponse;
import com.vilo.backend.dto.MessageResponse;
import com.vilo.backend.dto.SendMessageRequest;
import com.vilo.backend.entity.Conversation;
import com.vilo.backend.entity.Message;
import com.vilo.backend.entity.NotificationType;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.ConversationRepository;
import com.vilo.backend.repository.MessageRepository;
import com.vilo.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatService.class);

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatService(
            ConversationRepository conversationRepository,
            MessageRepository messageRepository,
            UserRepository userRepository,
            NotificationService notificationService,
            SimpMessagingTemplate messagingTemplate
    ) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public List<ConversationResponse> getConversations(User currentUser) {
        User me = userRepository.findById(currentUser.getId()).orElse(currentUser);
        java.util.Set<Long> myFollowingIds = me.getFollowing() != null
                ? me.getFollowing().stream().map(User::getId).collect(Collectors.toSet())
                : java.util.Collections.emptySet();
        java.util.Set<Long> myFollowerIds = me.getFollowers() != null
                ? me.getFollowers().stream().map(User::getId).collect(Collectors.toSet())
                : java.util.Collections.emptySet();

        List<Conversation> conversations = conversationRepository.findAllForUser(currentUser);
        List<ConversationResponse> result = new ArrayList<>();

        for (Conversation conv : conversations) {
            User otherUser = conv.getParticipant1().getId().equals(currentUser.getId())
                    ? conv.getParticipant2()
                    : conv.getParticipant1();

            long unreadCount = messageRepository.countByConversationAndRecipientAndIsReadFalse(conv, currentUser);

            boolean isFollowing = myFollowingIds.contains(otherUser.getId()) ||
                    (otherUser.getFollowers() != null && otherUser.getFollowers().stream().anyMatch(f -> f.getId().equals(me.getId())));
            boolean followsYou = myFollowerIds.contains(otherUser.getId()) ||
                    (otherUser.getFollowing() != null && otherUser.getFollowing().stream().anyMatch(f -> f.getId().equals(me.getId())));

            result.add(ConversationResponse.builder()
                    .id(conv.getId())
                    .otherUserId(otherUser.getId())
                    .otherUsername(otherUser.getUsername())
                    .otherDisplayName(otherUser.getDisplayName())
                    .otherAvatarUrl(otherUser.getAvatarUrl())
                    .isOtherVerified(otherUser.getIsVerified())
                    .lastMessageContent(conv.getLastMessageContent())
                    .lastMessageSenderId(conv.getLastMessageSenderId())
                    .lastMessageTime(conv.getLastMessageTime())
                    .unreadCount(unreadCount)
                    .isFollowing(isFollowing)
                    .followsYou(followsYou)
                    .isFriend(isFollowing && followsYou)
                    .build());
        }

        return result;
    }

    @Transactional
    public void markMessagesAsRead(User currentUser, Long otherUserId) {
        User otherUser = userRepository.findById(otherUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + otherUserId));

        Optional<Conversation> convOpt = conversationRepository.findBetweenUsers(currentUser, otherUser);
        if (convOpt.isEmpty()) return;

        Conversation conversation = convOpt.get();
        List<Message> unreadMessages = messageRepository
                .findByConversationAndRecipientAndIsReadFalse(conversation, currentUser);

        if (!unreadMessages.isEmpty()) {
            unreadMessages.forEach(message -> message.setIsRead(true));
            messageRepository.saveAll(unreadMessages);

            for (Message message : unreadMessages) {
                try {
                    MessageResponse receiptForSender = mapToMessageResponse(message, message.getSender());
                    messagingTemplate.convertAndSendToUser(
                            message.getSender().getUsername(),
                            "/queue/messages",
                            receiptForSender
                    );
                    messagingTemplate.convertAndSend(
                            "/topic/conversations/" + conversation.getId(),
                            receiptForSender
                    );
                } catch (Exception ex) {
                    log.warn("Failed to push read receipt for message {}: {}", message.getId(), ex.getMessage());
                }
            }
        }
    }

    @Transactional
    public Page<MessageResponse> getMessagesWithUser(User currentUser, Long otherUserId, int page, int size) {
        User otherUser = userRepository.findById(otherUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + otherUserId));

        Conversation conversation = getOrCreateConversation(currentUser, otherUser);

        // Mark unread messages as read and notify sender immediately so chat shows "Seen"
        markMessagesAsRead(currentUser, otherUserId);

        Pageable pageable = PageRequest.of(page, size);
        Page<Message> messagePage = messageRepository.findVisibleMessagesForUser(conversation, currentUser, pageable);

        return messagePage.map(m -> mapToMessageResponse(m, currentUser));
    }

    @Transactional
    public MessageResponse sendMessage(User sender, Long recipientId, SendMessageRequest request) {
        if (sender.getId().equals(recipientId)) {
            throw new BadRequestException("You cannot send a message to yourself");
        }

        User recipient = userRepository.findById(recipientId)
                .orElseThrow(() -> new ResourceNotFoundException("Recipient user not found with id: " + recipientId));

        Conversation conversation = getOrCreateConversation(sender, recipient);

        Message message = Message.builder()
                .conversation(conversation)
                .sender(sender)
                .recipient(recipient)
                .content(request.getContent().trim())
                .mediaUrl(request.getMediaUrl())
                .isRead(false)
                .deletedForEveryone(false)
                .deletedBySender(false)
                .deletedByRecipient(false)
                .build();

        Message savedMessage = messageRepository.save(message);

        // Update conversation last message details
        conversation.setLastMessageContent(savedMessage.getContent());
        conversation.setLastMessageSenderId(sender.getId());
        conversation.setLastMessageTime(savedMessage.getCreatedAt());
        conversationRepository.save(conversation);

        MessageResponse response = mapToMessageResponse(savedMessage, sender);
        MessageResponse recipientResponse = mapToMessageResponse(savedMessage, recipient);

        // Send via WebSocket STOMP
        try {
            // 1. Send to recipient user queue
            messagingTemplate.convertAndSendToUser(
                    recipient.getUsername(),
                    "/queue/messages",
                    recipientResponse
            );

            // 2. Send confirmation to sender user queue
            messagingTemplate.convertAndSendToUser(
                    sender.getUsername(),
                    "/queue/messages",
                    response
            );

            // 3. Broadcast to thread topic for active open chat
            messagingTemplate.convertAndSend(
                    "/topic/conversations/" + conversation.getId(),
                    response
            );
        } catch (Exception ex) {
            log.warn("Failed to push real-time STOMP message: {}", ex.getMessage());
        }

        // Notify recipient
        notificationService.sendNotification(
                recipient,
                sender,
                NotificationType.MESSAGE,
                "New message from " + sender.getDisplayName(),
                savedMessage.getContent(),
                String.valueOf(conversation.getId()),
                "CONVERSATION"
        );

        return response;
    }

    @Transactional
    public Conversation getOrCreateConversation(User userA, User userB) {
        return conversationRepository.findBetweenUsers(userA, userB)
                .orElseGet(() -> {
                    // Always order participant1 and participant2 deterministically by ID
                    User p1 = userA.getId() < userB.getId() ? userA : userB;
                    User p2 = userA.getId() < userB.getId() ? userB : userA;

                    Conversation newConv = Conversation.builder()
                            .participant1(p1)
                            .participant2(p2)
                            .lastMessageTime(Instant.now())
                            .build();

                    return conversationRepository.save(newConv);
                });
    }

    public MessageResponse mapToMessageResponse(Message msg, User viewer) {
        boolean isMe = msg.getSender().getId().equals(viewer.getId());
        boolean isDeletedForEveryone = Boolean.TRUE.equals(msg.getDeletedForEveryone());

        String displayContent = msg.getContent();
        String displayMedia = msg.getMediaUrl();

        if (isDeletedForEveryone) {
            displayContent = isMe ? "You deleted a message" : "This message was deleted";
            displayMedia = null;
        }

        return MessageResponse.builder()
                .id(msg.getId())
                .conversationId(msg.getConversation().getId())
                .senderId(msg.getSender().getId())
                .senderUsername(msg.getSender().getUsername())
                .senderDisplayName(msg.getSender().getDisplayName())
                .senderAvatarUrl(msg.getSender().getAvatarUrl())
                .recipientId(msg.getRecipient().getId())
                .recipientUsername(msg.getRecipient().getUsername())
                .content(displayContent)
                .mediaUrl(displayMedia)
                .isRead(msg.getIsRead())
                .isMe(isMe)
                .deleted(isDeletedForEveryone)
                .deletedForEveryone(isDeletedForEveryone)
                .createdAt(msg.getCreatedAt())
                .build();
    }

    @Transactional
    public void deleteConversation(User currentUser, Long otherUserId) {
        User otherUser = userRepository.findById(otherUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + otherUserId));
        Optional<Conversation> convOpt = conversationRepository.findBetweenUsers(currentUser, otherUser);
        if (convOpt.isPresent()) {
            Conversation conv = convOpt.get();
            // DO NOT DELETE DATABASE! Only mark status for current user.
            List<Message> messages = messageRepository.findByConversation(conv);
            for (Message m : messages) {
                if (m.getSender().getId().equals(currentUser.getId())) {
                    m.setDeletedBySender(true);
                }
                if (m.getRecipient().getId().equals(currentUser.getId())) {
                    m.setDeletedByRecipient(true);
                }
            }
            messageRepository.saveAll(messages);
        }
    }

    @Transactional
    public void deleteMessageForMe(User currentUser, Long messageId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new ResourceNotFoundException("Message not found with id: " + messageId));

        boolean isSender = message.getSender().getId().equals(currentUser.getId());
        boolean isRecipient = message.getRecipient().getId().equals(currentUser.getId());

        if (!isSender && !isRecipient) {
            throw new BadRequestException("You are not authorized to remove this message");
        }

        // DO NOT DELETE DATABASE! Soft status update only
        if (isSender) {
            message.setDeletedBySender(true);
        }
        if (isRecipient) {
            message.setDeletedByRecipient(true);
        }
        messageRepository.save(message);

        updateConversationLastMessage(message.getConversation());
    }

    @Transactional
    public MessageResponse deleteMessageForEveryone(User currentUser, Long messageId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new ResourceNotFoundException("Message not found with id: " + messageId));

        if (!message.getSender().getId().equals(currentUser.getId())) {
            throw new BadRequestException("Only the sender can remove a message for everyone");
        }

        Conversation conv = message.getConversation();

        // DO NOT DELETE DATABASE! Change status to deletedForEveryone
        message.setContent("This message was deleted");
        message.setMediaUrl(null);
        message.setDeletedForEveryone(true);
        Message saved = messageRepository.save(message);

        updateConversationLastMessage(conv);

        MessageResponse senderResponse = mapToMessageResponse(saved, message.getSender());
        MessageResponse recipientResponse = mapToMessageResponse(saved, message.getRecipient());

        // Broadcast to both users in real-time so both screens update to deleted status
        try {
            messagingTemplate.convertAndSendToUser(
                    message.getRecipient().getUsername(),
                    "/queue/messages",
                    recipientResponse
            );
            messagingTemplate.convertAndSendToUser(
                    message.getSender().getUsername(),
                    "/queue/messages",
                    senderResponse
            );
            messagingTemplate.convertAndSend(
                    "/topic/conversations/" + conv.getId(),
                    senderResponse
            );
        } catch (Exception ex) {
            log.warn("Failed to push delete for everyone real-time update: {}", ex.getMessage());
        }

        return senderResponse;
    }

    @Transactional
    public void deleteMessage(User currentUser, Long messageId) {
        deleteMessage(currentUser, messageId, false);
    }

    @Transactional
    public void deleteMessage(User currentUser, Long messageId, boolean forEveryone) {
        if (forEveryone) {
            deleteMessageForEveryone(currentUser, messageId);
        } else {
            deleteMessageForMe(currentUser, messageId);
        }
    }

    private void updateConversationLastMessage(Conversation conv) {
        Optional<Message> latest = messageRepository.findTopByConversationOrderByCreatedAtDesc(conv);
        if (latest.isPresent()) {
            Message lm = latest.get();
            conv.setLastMessageContent(lm.getContent());
            conv.setLastMessageSenderId(lm.getSender().getId());
            conv.setLastMessageTime(lm.getCreatedAt());
        } else {
            conv.setLastMessageContent("");
            conv.setLastMessageSenderId(null);
            conv.setLastMessageTime(null);
        }
        conversationRepository.save(conv);
    }
}
