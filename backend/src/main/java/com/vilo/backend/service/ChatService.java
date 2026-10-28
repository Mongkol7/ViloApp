package com.vilo.backend.service;

import com.vilo.backend.dto.ChatMessageRequest;
import com.vilo.backend.dto.ChatMessageResponse;
import com.vilo.backend.entity.ChatMessageEntity;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.ChatMessageDeletionEntity;
import com.vilo.backend.entity.ChatConversationHiddenEntity;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.exception.ForbiddenException;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.ChatMessageRepository;
import com.vilo.backend.repository.ChatMessageDeletionRepository;
import com.vilo.backend.repository.ChatConversationHiddenRepository;
import com.vilo.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.ArrayList;
import java.time.Instant;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final ChatMessageDeletionRepository chatMessageDeletionRepository;
    private final ChatConversationHiddenRepository chatConversationHiddenRepository;
    private final UserRepository userRepository;

    public ChatService(ChatMessageRepository chatMessageRepository,
                       ChatMessageDeletionRepository chatMessageDeletionRepository,
                       ChatConversationHiddenRepository chatConversationHiddenRepository,
                       UserRepository userRepository) {
        this.chatMessageRepository = chatMessageRepository;
        this.chatMessageDeletionRepository = chatMessageDeletionRepository;
        this.chatConversationHiddenRepository = chatConversationHiddenRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ChatMessageResponse saveMessage(User currentUser, ChatMessageRequest request) {
        ChatMessageEntity entity = new ChatMessageEntity();
        entity.setUser(currentUser);
        entity.setThreadId(normalizeThreadId(currentUser, request.getThreadId(), request.getRecipientHandle()));
        entity.setRecipientHandle(canonicalRecipientHandle(request.getRecipientHandle()));
        entity.setMessageText(request.getMessageText());
        entity.setProductTitle(request.getProductTitle());
        entity.setOrderReference(request.getOrderReference());
        entity.setProductPrice(request.getProductPrice());
        entity.setImageUrl(request.getImageUrl());
        entity.setContentType(normalizeContentType(request.getContentType(), request));
        entity.setLinkUrl(request.getLinkUrl());
        entity.setSharedVideoId(request.getSharedVideoId());
        entity.setSharedVideoUrl(request.getSharedVideoUrl());
        entity.setSharedVideoThumbnailUrl(request.getSharedVideoThumbnailUrl());
        entity.setSharedVideoCreator(request.getSharedVideoCreator());
        entity.setSharedVideoCaption(request.getSharedVideoCaption());
        entity.setIsMe(true);

        chatConversationHiddenRepository.deleteByThreadIdAndUserId(entity.getThreadId(), currentUser.getId());
        ChatMessageEntity saved = chatMessageRepository.save(entity);
        return ChatMessageResponse.fromEntity(saved, currentUser, userRepository);
    }

    @Transactional(readOnly = true)
    public List<ChatMessageResponse> getMessages(User currentUser) {
        return visibleMessages(chatMessageRepository.findUserMessages(currentUser.getId(), conversationHandlesFor(currentUser)), currentUser)
                .stream()
                .map(m -> ChatMessageResponse.fromEntity(m, currentUser, userRepository))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ChatMessageResponse> getMessagesByThread(User currentUser, String threadId) {
        return visibleMessages(chatMessageRepository.findThreadMessages(threadId, currentUser.getId(), conversationHandlesFor(currentUser)), currentUser)
                .stream()
                .map(m -> ChatMessageResponse.fromEntity(m, currentUser, userRepository))
                .collect(Collectors.toList());
    }

    @Transactional
    public ChatMessageResponse deleteMessage(User currentUser, Long messageId, String scope) {
        ChatMessageEntity message = chatMessageRepository.findById(messageId)
                .orElseThrow(() -> new ResourceNotFoundException("Message not found"));
        if (!isParticipant(currentUser, message)) {
            throw new ForbiddenException("You are not a participant in this conversation");
        }

        String normalizedScope = scope == null ? "ME" : scope.trim().toUpperCase(Locale.ROOT);
        if ("EVERYONE".equals(normalizedScope)) {
            if (message.getUser() == null || !message.getUser().getId().equals(currentUser.getId())) {
                throw new ForbiddenException("Only the sender can delete a message for everyone");
            }
            if (isOrderOrSystemMessage(message)) {
                throw new BadRequestException("Order and system messages can only be deleted for you");
            }
            message.setDeletedForEveryone(true);
            message.setDeletedAt(Instant.now());
            chatMessageRepository.save(message);
        } else if ("ME".equals(normalizedScope)) {
            if (!chatMessageDeletionRepository.existsByMessageIdAndUserId(messageId, currentUser.getId())) {
                chatMessageDeletionRepository.save(new ChatMessageDeletionEntity(messageId, currentUser.getId()));
            }
        } else {
            throw new BadRequestException("Deletion scope must be ME or EVERYONE");
        }

        return ChatMessageResponse.fromEntity(message, currentUser, userRepository);
    }

    @Transactional
    public void hideConversation(User currentUser, String threadId) {
        if (threadId == null || threadId.isBlank()) {
            throw new BadRequestException("threadId is required");
        }
        String normalizedThreadId = threadId.trim();
        List<ChatMessageEntity> messages = chatMessageRepository.findThreadMessages(
                normalizedThreadId, currentUser.getId(), conversationHandlesFor(currentUser));
        if (messages.isEmpty()) {
            throw new ResourceNotFoundException("Conversation not found");
        }
        ChatConversationHiddenEntity hidden = chatConversationHiddenRepository
                .findByThreadIdAndUserId(normalizedThreadId, currentUser.getId())
                .orElseGet(() -> new ChatConversationHiddenEntity(normalizedThreadId, currentUser.getId(), Instant.now()));
        hidden.setHiddenAt(Instant.now());
        chatConversationHiddenRepository.save(hidden);
    }

    private List<ChatMessageEntity> visibleMessages(List<ChatMessageEntity> messages, User currentUser) {
        if (messages == null || messages.isEmpty()) return List.of();
        Set<Long> messageIds = messages.stream()
                .map(ChatMessageEntity::getId)
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());
        Set<Long> deletedMessageIds = chatMessageDeletionRepository
                .findByMessageIdInAndUserId(messageIds, currentUser.getId())
                .stream()
                .map(ChatMessageDeletionEntity::getMessageId)
                .collect(Collectors.toSet());
        java.util.Map<String, Instant> hiddenThreads = chatConversationHiddenRepository.findByUserId(currentUser.getId())
                .stream()
                .collect(Collectors.toMap(ChatConversationHiddenEntity::getThreadId,
                        ChatConversationHiddenEntity::getHiddenAt,
                        (first, second) -> first.isAfter(second) ? first : second));
        List<ChatMessageEntity> visible = new ArrayList<>();
        for (ChatMessageEntity message : messages) {
            if (message.getId() != null && deletedMessageIds.contains(message.getId())) {
                continue;
            }
            Instant hiddenAt = hiddenThreads.get(message.getThreadId());
            if (hiddenAt != null && message.getCreatedAt() != null && !message.getCreatedAt().isAfter(hiddenAt)) {
                continue;
            }
            visible.add(message);
        }
        return visible;
    }

    private boolean isParticipant(User currentUser, ChatMessageEntity message) {
        if (message.getUser() != null && message.getUser().getId().equals(currentUser.getId())) return true;
        String recipient = message.getRecipientHandle() == null ? "" : message.getRecipientHandle().toLowerCase(Locale.ROOT);
        return conversationHandlesFor(currentUser).contains(recipient);
    }

    private boolean isOrderOrSystemMessage(ChatMessageEntity message) {
        if (message.getOrderReference() != null && !message.getOrderReference().isBlank()) return true;
        String text = message.getMessageText() == null ? "" : message.getMessageText().trim().toLowerCase(Locale.ROOT);
        return text.startsWith("order cancelled by ") || text.contains("order inquiry") ||
                text.contains("i would like to order");
    }

    private String normalizeContentType(String raw, ChatMessageRequest request) {
        if (raw != null && !raw.isBlank()) return raw.trim().toUpperCase(Locale.ROOT);
        if (request.getSharedVideoId() != null || (request.getSharedVideoUrl() != null && !request.getSharedVideoUrl().isBlank())) return "VIDEO";
        if (request.getLinkUrl() != null && !request.getLinkUrl().isBlank()) return "LINK";
        if (request.getImageUrl() != null && !request.getImageUrl().isBlank()) return "IMAGE";
        return "TEXT";
    }

    private String canonicalRecipientHandle(String rawHandle) {
        User recipient = resolveRecipient(rawHandle);
        if (recipient != null && recipient.getUsername() != null && !recipient.getUsername().isBlank()) {
            return recipient.getUsername().trim();
        }
        if (rawHandle == null) return "";
        String cleaned = rawHandle.replace("@", "").trim();
        return cleaned.toLowerCase(Locale.ROOT);
    }

    private String normalizeThreadId(User sender, String requestedThreadId, String recipientHandle) {
        User recipient = resolveRecipient(recipientHandle);
        if (sender != null && recipient != null) {
            return buildThreadId(sender.getUsername(), recipient.getUsername());
        }
        return requestedThreadId;
    }

    private String buildThreadId(String firstHandle, String secondHandle) {
        String first = firstHandle == null ? "" : firstHandle.replace("@", "").trim().toLowerCase(Locale.ROOT);
        String second = secondHandle == null ? "" : secondHandle.replace("@", "").trim().toLowerCase(Locale.ROOT);
        if (first.isEmpty()) return "chat_" + second;
        if (second.isEmpty()) return "chat_" + first;
        return first.compareTo(second) < 0
                ? "dm_" + first + "_" + second
                : "dm_" + second + "_" + first;
    }

    private User resolveRecipient(String handle) {
        if (handle == null || handle.isBlank()) return null;
        String clean = handle.replace("@", "").trim();
        if (clean.isEmpty()) return null;

        return userRepository.findByUsernameIgnoreCase(clean)
                .or(() -> userRepository.findByUsernameIgnoreCase(clean.replace(' ', '_')))
                .or(() -> userRepository.findByUsernameIgnoreCase(clean.replace('_', ' ')))
                .or(() -> uniqueDisplayName(clean))
                .or(() -> uniqueDisplayName(clean.replace('_', ' ')))
                .or(() -> uniqueDisplayName(clean.replace(' ', '_')))
                .or(() -> resolveStoreOrAlias(clean))
                .orElse(null);
    }

    private java.util.Optional<User> resolveStoreOrAlias(String alias) {
        if (alias == null || alias.isBlank()) return java.util.Optional.empty();
        String lower = alias.toLowerCase(Locale.ROOT);
        // Map store names and merchant handles to platform sellers
        if (lower.contains("techhorizon") || lower.contains("techgear") || lower.contains("god_gear") ||
            lower.contains("god gear") || lower.contains("master_tech") || lower.contains("master tech") ||
            lower.contains("pulse") || lower.contains("aura") || lower.contains("vilo_deals") ||
            lower.contains("vilo deals") || lower.contains("seller") || lower.contains("techpro")) {
            return userRepository.findByUsernameIgnoreCase("rithysak")
                    .or(() -> userRepository.findByUsernameIgnoreCase("mongkol"));
        }
        return java.util.Optional.empty();
    }

    private java.util.Optional<User> uniqueDisplayName(String value) {
        List<User> matches = userRepository.findByDisplayNameIgnoreCase(value);
        if (matches.size() == 1) {
            return java.util.Optional.of(matches.get(0));
        }
        return java.util.Optional.empty();
    }

    private Set<String> conversationHandlesFor(User user) {
        Set<String> handles = new HashSet<>();
        addHandleVariants(handles, user.getUsername());
        addHandleVariants(handles, user.getDisplayName());
        if ("rithysak".equalsIgnoreCase(user.getUsername())) {
            // The seeded marketplace catalog belongs to rithysak. Do not
            // expose store-alias messages to mongkol as well, otherwise a
            // cancellation from one seller can appear in the other seller's
            // conversation.
            addHandleVariants(handles, "techhorizon global");
            addHandleVariants(handles, "techhorizon");
            addHandleVariants(handles, "techgear official");
            addHandleVariants(handles, "god gear official");
            addHandleVariants(handles, "master tech");
            addHandleVariants(handles, "pulse essentials");
            addHandleVariants(handles, "vilo deals");
            addHandleVariants(handles, "seller");
        }
        if (handles.isEmpty()) {
            handles.add("");
        }
        return handles;
    }

    private void addHandleVariants(Set<String> handles, String raw) {
        if (raw == null || raw.isBlank()) return;
        String trimmed = raw.trim();
        String noAt = trimmed.startsWith("@") ? trimmed.substring(1) : trimmed;
        String lower = noAt.toLowerCase(Locale.ROOT);
        handles.add(lower);
        handles.add("@" + lower);
        String underscored = lower.replace(' ', '_');
        handles.add(underscored);
        handles.add("@" + underscored);
        String spaced = lower.replace('_', ' ');
        handles.add(spaced);
        handles.add("@" + spaced);
    }
}
