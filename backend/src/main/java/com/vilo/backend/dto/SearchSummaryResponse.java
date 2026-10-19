package com.vilo.backend.dto;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class SearchSummaryResponse {
    private String query;
    private String type;
    private List<UserResponse> users = new ArrayList<>();
    private List<SoundResponse> sounds = new ArrayList<>();
    private List<HashtagResponse> hashtags = new ArrayList<>();
    private List<Map<String, Object>> trendingVideos = new ArrayList<>();

    public SearchSummaryResponse() {}

    public SearchSummaryResponse(String query, String type) {
        this.query = query;
        this.type = type;
    }

    public String getQuery() {
        return query;
    }

    public void setQuery(String query) {
        this.query = query;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public List<UserResponse> getUsers() {
        return users;
    }

    public void setUsers(List<UserResponse> users) {
        this.users = users;
    }

    public List<SoundResponse> getSounds() {
        return sounds;
    }

    public void setSounds(List<SoundResponse> sounds) {
        this.sounds = sounds;
    }

    public List<HashtagResponse> getHashtags() {
        return hashtags;
    }

    public void setHashtags(List<HashtagResponse> hashtags) {
        this.hashtags = hashtags;
    }

    public List<Map<String, Object>> getTrendingVideos() {
        return trendingVideos;
    }

    public void setTrendingVideos(List<Map<String, Object>> trendingVideos) {
        this.trendingVideos = trendingVideos;
    }

    public int getTotalCount() {
        return (users != null ? users.size() : 0) +
               (sounds != null ? sounds.size() : 0) +
               (hashtags != null ? hashtags.size() : 0) +
               (trendingVideos != null ? trendingVideos.size() : 0);
    }
}
