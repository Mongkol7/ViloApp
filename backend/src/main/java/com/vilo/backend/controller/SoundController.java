package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.entity.User;
import com.vilo.backend.service.SoundService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/sounds")
@Tag(name = "Sounds & Audio", description = "Endpoints for discovering sounds, audio metadata, and related short-form videos")
public class SoundController {

    private final SoundService soundService;

    public SoundController(SoundService soundService) {
        this.soundService = soundService;
    }

    /**
     * GET /api/v1/sounds
     * Lists all available sound tracks for the optional sound picker.
     */
    @GetMapping
    @Operation(summary = "Get all sounds", description = "Retrieves all available sound tracks for audio picking")
    public ResponseEntity<ApiResponse<List<SoundResponse>>> getAllSounds() {
        List<SoundResponse> sounds = soundService.getAllSounds();
        return ResponseEntity.ok(ApiResponse.ok("Sounds fetched successfully", sounds));
    }

    @GetMapping("/trending")
    @Operation(summary = "Get trending sounds", description = "Retrieves popular sounds prioritized by total video usage count")
    public ResponseEntity<ApiResponse<List<SoundResponse>>> getTrendingSounds() {
        List<SoundResponse> sounds = soundService.getTrendingSounds();
        return ResponseEntity.ok(ApiResponse.ok("Trending sounds fetched successfully", sounds));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get sound details", description = "Retrieves audio metadata, duration, waveform data, and artist info")
    public ResponseEntity<ApiResponse<SoundResponse>> getSoundById(@PathVariable Long id) {
        SoundResponse sound = soundService.getSoundById(id);
        return ResponseEntity.ok(ApiResponse.ok("Sound details fetched successfully", sound));
    }

    /**
     * GET /api/v1/sounds/{id}/videos
     * Return sound metadata (including creator name and usageCount) + all videos/photos using this music.
     */
    @GetMapping("/{id}/videos")
    @Operation(summary = "Get videos using sound", description = "Retrieves sound metadata + videos that feature this sound track")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getVideosBySoundId(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        Map<String, Object> result = soundService.getSoundWithVideos(id, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Videos using sound fetched successfully", result));
    }
}
