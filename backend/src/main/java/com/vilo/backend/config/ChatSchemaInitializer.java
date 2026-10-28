package com.vilo.backend.config;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Adds the chat deletion/rich-message schema without touching existing rows.
 *
 * Hibernate update normally performs this work, but existing development
 * databases can be running with an older schema while the application has
 * already been rebuilt. These statements are idempotent and additive only.
 */
@Component
public class ChatSchemaInitializer {

    private final JdbcTemplate jdbcTemplate;

    public ChatSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void initialize() {
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS content_type VARCHAR(20) DEFAULT 'TEXT'");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS link_url TEXT");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS shared_video_id BIGINT");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS shared_video_url TEXT");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS shared_video_thumbnail_url TEXT");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS shared_video_creator VARCHAR(150)");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS shared_video_caption TEXT");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS deleted_for_everyone BOOLEAN NOT NULL DEFAULT FALSE");
        jdbcTemplate.execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE");

        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS chat_message_deletions (
                    id BIGSERIAL PRIMARY KEY,
                    message_id BIGINT NOT NULL,
                    user_id BIGINT NOT NULL,
                    deleted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT uk_chat_message_deletion_user UNIQUE (message_id, user_id)
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS chat_conversation_hides (
                    id BIGSERIAL PRIMARY KEY,
                    thread_id VARCHAR(100) NOT NULL,
                    user_id BIGINT NOT NULL,
                    hidden_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT uk_chat_conversation_hide_user UNIQUE (thread_id, user_id)
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS notifications (
                    id BIGSERIAL PRIMARY KEY,
                    recipient_id BIGINT NOT NULL,
                    actor_id BIGINT NOT NULL,
                    notification_type VARCHAR(20) NOT NULL,
                    video_id BIGINT,
                    comment_id BIGINT,
                    target_user_id BIGINT,
                    comment_excerpt VARCHAR(240),
                    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    read_at TIMESTAMP WITH TIME ZONE
                )
                """);
        jdbcTemplate.execute("CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created ON notifications (recipient_id, created_at DESC)");
    }
}
