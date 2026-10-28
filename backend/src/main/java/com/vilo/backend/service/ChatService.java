package com.vilo.backend.service;

import com.vilo.backend.dto.ChatMessageRequest;
import com.vilo.backend.dto.ChatMessageResponse;
import com.vilo.backend.entity.ChatMessageEntity;
import com.vilo.backend.entity.User;
import com.vilo.backend.repository.ChatMessageRepository;
import com.vilo.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;

    public ChatService(ChatMessageRepository chatMessageRepository, UserRepository userRepository) {
        this.chatMessageRepository = chatMessageRepository;
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
        entity.setIsMe(true);

        ChatMessageEntity saved = chatMessageRepository.save(entity);
        return ChatMessageResponse.fromEntity(saved, currentUser, userRepository);
    }

    @Transactional(readOnly = true)
    public List<ChatMessageResponse> getMessages(User currentUser) {
        return chatMessageRepository.findUserMessages(currentUser.getId(), conversationHandlesFor(currentUser))
                .stream()
                .map(m -> ChatMessageResponse.fromEntity(m, currentUser, userRepository))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ChatMessageResponse> getMessagesByThread(User currentUser, String threadId) {
        return chatMessageRepository.findThreadMessages(threadId, currentUser.getId(), conversationHandlesFor(currentUser))
                .stream()
                .map(m -> ChatMessageResponse.fromEntity(m, currentUser, userRepository))
                .collect(Collectors.toList());
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
