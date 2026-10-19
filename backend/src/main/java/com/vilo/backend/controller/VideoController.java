package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.VideoResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.VideoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/videos")
@Tag(name = "Video Feed & Engine", description = "Endpoints for home video feeds (For You and Following) and creator videos")
public class VideoController {

    private final VideoService videoService;

    public VideoController(VideoService videoService) {
        this.videoService = videoService;
    }

    @GetMapping("/feed")
    @Operation(summary = "Get video feed", description = "Retrieves paginated video feed filtered by FOR_YOU or FOLLOWING")
    public ResponseEntity<ApiResponse<List<VideoResponse>>> getVideoFeed(
            @Parameter(description = "Feed type: FOR_YOU or FOLLOWING")
            @RequestParam(value = "type", defaultValue = "FOR_YOU") String type,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "20") int size,
            @AuthenticationPrincipal User currentUser
    ) {
        List<VideoResponse> feed = videoService.getVideoFeed(type, currentUser, page, size);
        return ResponseEntity.ok(ApiResponse.ok("Video feed fetched successfully", feed));
    }

    @GetMapping("/user/{identifier}")
    @Operation(summary = "Get creator videos", description = "Retrieves all public videos posted by a specific user (by ID or username)")
    public ResponseEntity<ApiResponse<List<VideoResponse>>> getUserVideos(
            @PathVariable String identifier,
            @AuthenticationPrincipal User currentUser
    ) {
        List<VideoResponse> videos = videoService.getUserVideos(identifier, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("User videos fetched successfully", videos));
    }
}
