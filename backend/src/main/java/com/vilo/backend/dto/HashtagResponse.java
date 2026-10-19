package com.vilo.backend.dto;

import com.vilo.backend.entity.Hashtag;

public class HashtagResponse {
    private Long id;
    private String tag;
    private String formattedTag;
    private Long usageCount;
    private String formattedUsageCount;
    private Boolean isTrending;

    public HashtagResponse() {}

    public static HashtagResponse fromEntity(Hashtag hashtag) {
        HashtagResponse dto = new HashtagResponse();
        dto.setId(hashtag.getId());
        dto.setTag(hashtag.getTag());
        dto.setFormattedTag("#" + hashtag.getTag());
        dto.setUsageCount(hashtag.getUsageCount());
        dto.setIsTrending(hashtag.getIsTrending());
        dto.setFormattedUsageCount(formatCount(hashtag.getUsageCount()));
        return dto;
    }

    private static String formatCount(Long count) {
        if (count == null || count <= 0) return "0 views";
        if (count >= 1_000_000) {
            return String.format("%.1fM views", count / 1_000_000.0);
        } else if (count >= 1_000) {
            return String.format("%.1fK views", count / 1_000.0);
        }
        return count + " views";
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag;
    }

    public String getFormattedTag() {
        return formattedTag;
    }

    public void setFormattedTag(String formattedTag) {
        this.formattedTag = formattedTag;
    }

    public Long getUsageCount() {
        return usageCount;
    }

    public void setUsageCount(Long usageCount) {
        this.usageCount = usageCount;
    }

    public String getFormattedUsageCount() {
        return formattedUsageCount;
    }

    public void setFormattedUsageCount(String formattedUsageCount) {
        this.formattedUsageCount = formattedUsageCount;
    }

    public Boolean getIsTrending() {
        return isTrending;
    }

    public void setIsTrending(Boolean trending) {
        isTrending = trending;
    }
}
