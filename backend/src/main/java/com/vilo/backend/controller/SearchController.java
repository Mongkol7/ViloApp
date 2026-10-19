package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.SearchHistoryResponse;
import com.vilo.backend.dto.SearchSummaryResponse;
import com.vilo.backend.service.SearchService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@Tag(name = "Search & Discovery", description = "Endpoints for global entity search, trending discovery, and user search history")
public class SearchController {

    private final SearchService searchService;

    public SearchController(SearchService searchService) {
        this.searchService = searchService;
    }

    @GetMapping("/search")
    @Operation(summary = "Global search", description = "Searches across users, sounds, hashtags, and videos by query string and type filter")
    public ResponseEntity<ApiResponse<SearchSummaryResponse>> search(
            @Parameter(description = "Search query keyword") @RequestParam(value = "q", defaultValue = "") String query,
            @Parameter(description = "Filter type: ALL, USERS, SOUNDS, HASHTAGS, VIDEOS") @RequestParam(value = "type", defaultValue = "ALL") String type,
            Authentication authentication) {
        String username = authentication != null ? authentication.getName() : null;
        SearchSummaryResponse result = searchService.search(query, type, username);
        return ResponseEntity.ok(ApiResponse.ok("Search completed successfully", result));
    }

    @GetMapping("/explore/trending")
    @Operation(summary = "Explore trending content", description = "Retrieves trending hashtags, popular sounds, and featured viral videos")
    public ResponseEntity<ApiResponse<SearchSummaryResponse>> getTrendingExplore() {
        SearchSummaryResponse trending = searchService.getTrendingExplore();
        return ResponseEntity.ok(ApiResponse.ok("Trending explore content fetched successfully", trending));
    }

    @GetMapping("/search/history")
    @Operation(summary = "Get user search history", description = "Retrieves recent searches made by the authenticated user")
    public ResponseEntity<ApiResponse<List<SearchHistoryResponse>>> getSearchHistory(Authentication authentication) {
        String username = authentication != null ? authentication.getName() : null;
        List<SearchHistoryResponse> history = searchService.getSearchHistory(username);
        return ResponseEntity.ok(ApiResponse.ok("Search history fetched successfully", history));
    }

    @DeleteMapping("/search/history")
    @Operation(summary = "Clear all search history", description = "Clears all search history records for the current user")
    public ResponseEntity<ApiResponse<Void>> clearSearchHistory(Authentication authentication) {
        if (authentication != null) {
            searchService.clearSearchHistory(authentication.getName());
        }
        return ResponseEntity.ok(ApiResponse.ok("Search history cleared successfully", null));
    }

    @DeleteMapping("/search/history/{id}")
    @Operation(summary = "Delete specific search item", description = "Deletes a single search entry from user's history")
    public ResponseEntity<ApiResponse<Void>> deleteSearchHistoryItem(@PathVariable Long id, Authentication authentication) {
        if (authentication != null) {
            searchService.deleteSearchHistoryItem(authentication.getName(), id);
        }
        return ResponseEntity.ok(ApiResponse.ok("Search item deleted successfully", null));
    }
}
