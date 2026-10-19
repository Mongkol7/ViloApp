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
import java.util.Set;
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
    public Page<MessageResponse> getMessagesWithUser(User currentUser, Long otherUserId, int page, int size) {
        User otherUser = userRepository.findById(otherUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + otherUserId));

        Conversation conversation = getOrCreateConversation(currentUser, otherUser);

        // Mark unread messages sent to current user as read
        messageRepository.markConversationMessagesAsRead(conversation, currentUser);

        Pageable pageable = PageRequest.of(page, size);
        Page<Message> messagePage = messageRepository.findByConversationOrderByCreatedAtDesc(conversation, pageable);

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

        return MessageResponse.builder()
                .id(msg.getId())
                .conversationId(msg.getConversation().getId())
                .senderId(msg.getSender().getId())
                .senderUsername(msg.getSender().getUsername())
                .senderDisplayName(msg.getSender().getDisplayName())
                .senderAvatarUrl(msg.getSender().getAvatarUrl())
                .recipientId(msg.getRecipient().getId())
                .recipientUsername(msg.getRecipient().getUsername())
                .content(msg.getContent())
                .mediaUrl(msg.getMediaUrl())
                .isRead(msg.getIsRead())
                .isMe(isMe)
                .createdAt(msg.getCreatedAt())
                .build();
    }
}
