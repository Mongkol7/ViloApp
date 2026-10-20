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

    /**
     * POST /api/v1/sounds/upload
     * Uploads an audio/music file and creates a new Sound track.
     */
    @PostMapping("/upload")
    @Operation(summary = "Upload sound track", description = "Uploads a new audio/music file and creates a sound entry")
    public ResponseEntity<ApiResponse<SoundResponse>> uploadSound(
            @RequestParam(value = "audioFile", required = false) org.springframework.web.multipart.MultipartFile audioFile,
            @RequestParam(value = "musicFile", required = false) org.springframework.web.multipart.MultipartFile musicFile,
            @RequestParam(value = "file", required = false) org.springframework.web.multipart.MultipartFile file,
            @RequestParam(value = "coverFile", required = false) org.springframework.web.multipart.MultipartFile coverFile,
            @RequestParam(value = "thumbnailFile", required = false) org.springframework.web.multipart.MultipartFile thumbnailFile,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "artist", required = false) String artist,
            @RequestParam(value = "coverUrl", required = false) String coverUrl,
            @AuthenticationPrincipal User currentUser
    ) {
        org.springframework.web.multipart.MultipartFile effectiveFile = (audioFile != null && !audioFile.isEmpty()) ? audioFile
                : ((musicFile != null && !musicFile.isEmpty()) ? musicFile : file);
        if (effectiveFile == null || effectiveFile.isEmpty()) {
            throw new IllegalArgumentException("Audio file must be provided");
        }
        org.springframework.web.multipart.MultipartFile effectiveCoverFile = (coverFile != null && !coverFile.isEmpty()) ? coverFile : thumbnailFile;
        SoundResponse response = soundService.uploadSound(effectiveFile, effectiveCoverFile, title, artist, coverUrl, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Sound uploaded successfully", response));
    }

    /**
     * DELETE /api/v1/sounds/{id}
     * Deletes a sound track. Owner-only operation.
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "Delete sound track", description = "Deletes a sound track. Only the owner of the sound can delete it.")
    public ResponseEntity<ApiResponse<Void>> deleteSound(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser
    ) {
        soundService.deleteSound(id, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Sound deleted successfully", null));
    }

    /**
     * PATCH /api/v1/sounds/{id}
     * Allows the creator to update track title and/or upload a custom cover image.
     */
    @PatchMapping(value = "/{id}")
    @Operation(summary = "Update sound cover or metadata", description = "Allows the creator to update track title or upload a custom cover image")
    public ResponseEntity<ApiResponse<SoundResponse>> updateSound(
            @PathVariable Long id,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "coverFile", required = false) org.springframework.web.multipart.MultipartFile coverFile,
            @RequestParam(value = "coverUrl", required = false) String coverUrl,
            @AuthenticationPrincipal User currentUser
    ) {
        SoundResponse response = soundService.updateSound(id, title, coverFile, coverUrl, currentUser);
        return ResponseEntity.ok(ApiResponse.ok("Sound updated successfully", response));
    }
}
