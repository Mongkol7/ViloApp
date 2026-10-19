package com.vilo.backend.dto;

import com.vilo.backend.entity.SearchHistory;
import java.time.LocalDateTime;

public class SearchHistoryResponse {
    private Long id;
    private String query;
    private String searchType;
    private LocalDateTime createdAt;

    public SearchHistoryResponse() {}

    public static SearchHistoryResponse fromEntity(SearchHistory history) {
        SearchHistoryResponse dto = new SearchHistoryResponse();
        dto.setId(history.getId());
        dto.setQuery(history.getQuery());
        dto.setSearchType(history.getSearchType());
        dto.setCreatedAt(history.getCreatedAt());
        return dto;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getQuery() {
        return query;
    }

    public void setQuery(String query) {
        this.query = query;
    }

    public String getSearchType() {
        return searchType;
    }

    public void setSearchType(String searchType) {
        this.searchType = searchType;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
