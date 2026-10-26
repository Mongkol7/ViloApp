package com.vilo.backend.service;

import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.entity.Sound;
import com.vilo.backend.entity.User;
import com.vilo.backend.entity.Video;
import com.vilo.backend.exception.ForbiddenException;
import com.vilo.backend.repository.SoundRepository;
import com.vilo.backend.repository.VideoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SoundServiceTest {

    @Mock
    private SoundRepository soundRepository;

    @Mock
    private VideoRepository videoRepository;

    @Mock
    private FileStorageService fileStorageService;

    @InjectMocks
    private SoundService soundService;

    private User owner;
    private User otherUser;
    private Sound testSound;

    @BeforeEach
    void setUp() {
        owner = new User();
        owner.setId(10L);
        owner.setUsername("owner_user");

        otherUser = new User();
        otherUser.setId(20L);
        otherUser.setUsername("hacker_user");

        testSound = new Sound("Epic Synth", 10L, "owner_user", "/uploads/music/epic.mp3", "/uploads/thumbnails/cover.jpg", 5L);
        testSound.setId(100L);
    }

    @Test
    void uploadSound_withCoverFile_storesBothFilesAndReturnsResponse() {
        MockMultipartFile audioFile = new MockMultipartFile("audioFile", "beat.mp3", "audio/mpeg", new byte[]{1, 2, 3});
        MockMultipartFile coverFile = new MockMultipartFile("coverFile", "art.jpg", "image/jpeg", new byte[]{4, 5, 6});

        when(fileStorageService.storeFile(eq(audioFile), eq("music"))).thenReturn("/uploads/music/beat.mp3");
        when(fileStorageService.storeFile(eq(coverFile), eq("thumbnails"))).thenReturn("/uploads/thumbnails/art.jpg");
        when(soundRepository.save(any(Sound.class))).thenAnswer(invocation -> {
            Sound s = invocation.getArgument(0);
            s.setId(101L);
            return s;
        });

        SoundResponse response = soundService.uploadSound(audioFile, coverFile, "My New Sound", null, null, owner);

        assertNotNull(response);
        assertEquals("My New Sound", response.getTitle());
        assertEquals("/uploads/music/beat.mp3", response.getAudioUrl());
        assertEquals("/uploads/thumbnails/art.jpg", response.getCoverUrl());
        assertEquals(10L, response.getCreatorId());
        assertEquals("owner_user", response.getCreatorUsername());
    }

    @Test
    void deleteSound_byOwner_clearsVideoSoundIdAndDeletes() {
        when(soundRepository.findById(100L)).thenReturn(Optional.of(testSound));

        Video video1 = new Video();
        video1.setId(501L);
        video1.setSoundId(100L);

        List<Video> videos = new ArrayList<>();
        videos.add(video1);
        when(videoRepository.findBySoundIdOrderByCreatedAtDesc(100L)).thenReturn(videos);

        soundService.deleteSound(100L, owner);

        assertNull(video1.getSoundId());
        verify(videoRepository).saveAll(videos);
        verify(videoRepository).clearSoundId(100L);
        verify(soundRepository).delete(testSound);
    }

    @Test
    void deleteSound_byNonOwner_throwsForbiddenException() {
        when(soundRepository.findById(100L)).thenReturn(Optional.of(testSound));

        assertThrows(ForbiddenException.class, () -> soundService.deleteSound(100L, otherUser));
        verify(soundRepository, never()).delete(any());
        verify(videoRepository, never()).clearSoundId(anyLong());
    }

    @Test
    void deleteSound_unauthenticated_throwsForbiddenException() {
        when(soundRepository.findById(100L)).thenReturn(Optional.of(testSound));

        assertThrows(ForbiddenException.class, () -> soundService.deleteSound(100L, null));
        verify(soundRepository, never()).delete(any());
    }
}
