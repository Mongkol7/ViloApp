package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.CreateStoryRequest;
import com.vilo.backend.dto.StoryResponse;
import com.vilo.backend.dto.StoryViewerResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.StoryService;
import com.vilo.backend.service.FileStorageService;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/stories")
public class StoryController {

    private final StoryService storyService;
    private final FileStorageService fileStorageService;

    public StoryController(StoryService storyService, FileStorageService fileStorageService) {
        this.storyService = storyService;
        this.fileStorageService = fileStorageService;
    }

    @GetMapping({"", "/active"})
    public ResponseEntity<ApiResponse<List<StoryResponse>>> getActiveStories(
            @AuthenticationPrincipal User currentUser
    ) {
        List<StoryResponse> stories = storyService.getActiveStories(currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Active stories retrieved successfully", stories));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<StoryResponse>> createStory(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody CreateStoryRequest request
    ) {
        StoryResponse story = storyService.createStory(currentUser, request);
        return ResponseEntity.ok(ApiResponse.ok("Story posted successfully", story));
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<StoryResponse>> uploadStoryMedia(
            @AuthenticationPrincipal User currentUser,
            @RequestPart("file") MultipartFile file,
            @RequestParam(defaultValue = "") String message,
            @RequestParam(defaultValue = "VIDEO") String mediaType,
            @RequestParam(defaultValue = "PUBLIC") String privacy,
            @RequestParam(defaultValue = "sunset") String backgroundGradient,
            @RequestParam(defaultValue = "24") int expiresInHours
    ) {
        final String folder = "IMAGE".equalsIgnoreCase(mediaType) ? "photos" : "videos";
        final String mediaUrl = fileStorageService.storeFile(file, folder);
        final CreateStoryRequest request = new CreateStoryRequest();
        request.setMessage(message);
        request.setMediaUrl(mediaUrl);
        request.setMediaType(mediaType);
        request.setPrivacy(privacy);
        request.setBackgroundGradient(backgroundGradient);
        request.setExpiresInHours(expiresInHours);
        StoryResponse story = storyService.createStory(currentUser, request);
        return ResponseEntity.ok(ApiResponse.ok("Story uploaded successfully", story));
    }

    @PostMapping("/{id}/view")
    public ResponseEntity<ApiResponse<StoryResponse>> recordView(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long id
    ) {
        StoryResponse story = storyService.recordView(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Story view recorded", story));
    }

    @PostMapping("/{id}/react")
    public ResponseEntity<ApiResponse<StoryResponse>> reactStory(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long id
    ) {
        StoryResponse story = storyService.reactStory(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Story reaction recorded", story));
    }

    @GetMapping("/{id}/viewers")
    public ResponseEntity<ApiResponse<List<StoryViewerResponse>>> getStoryViewers(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long id
    ) {
        List<StoryViewerResponse> viewers = storyService.getStoryViewers(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Story viewers retrieved", viewers));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> deleteStory(
            @AuthenticationPrincipal User currentUser,
            @PathVariable Long id
    ) {
        storyService.deleteStory(currentUser, id);
        return ResponseEntity.ok(ApiResponse.ok("Story deleted successfully", Map.of("storyId", id)));
    }
}
