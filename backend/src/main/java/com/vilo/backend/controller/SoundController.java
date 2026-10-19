package com.vilo.backend.controller;

import com.vilo.backend.common.ApiResponse;
import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.service.SoundService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
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

    @GetMapping("/{id}/videos")
    @Operation(summary = "Get videos using sound", description = "Retrieves a paginated list of short videos that feature this sound track")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getVideosBySoundId(@PathVariable Long id) {
        List<Map<String, Object>> videos = soundService.getVideosBySoundId(id);
        return ResponseEntity.ok(ApiResponse.ok("Videos using sound fetched successfully", videos));
    }
}
