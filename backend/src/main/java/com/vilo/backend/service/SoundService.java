package com.vilo.backend.service;

import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.entity.Sound;
import com.vilo.backend.exception.ResourceNotFoundException;
import com.vilo.backend.repository.SoundRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SoundService {

    private final SoundRepository soundRepository;

    public SoundService(SoundRepository soundRepository) {
        this.soundRepository = soundRepository;
    }

    @Transactional(readOnly = true)
    public List<SoundResponse> getTrendingSounds() {
        List<Sound> sounds = soundRepository.findByIsTrendingTrueOrderByUsageCountDesc();
        if (sounds.isEmpty()) {
            sounds = soundRepository.findAllByOrderByUsageCountDesc(PageRequest.of(0, 10));
        }
        return sounds.stream().map(SoundResponse::fromEntity).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SoundResponse getSoundById(Long id) {
        Sound sound = soundRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + id));
        return SoundResponse.fromEntity(sound);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getVideosBySoundId(Long soundId) {
        // Verify sound exists
        Sound sound = soundRepository.findById(soundId)
                .orElseThrow(() -> new ResourceNotFoundException("Sound not found with id: " + soundId));

        // Returns featured videos utilizing this sound
        List<Map<String, Object>> videos = new ArrayList<>();
        String[] mockThumbs = {
                "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500&auto=format&fit=crop&q=80"
        };
        String[] viewCounts = {"1.8M", "820K", "542K", "310K", "295K", "180K", "125K", "98K", "64K"};

        for (int i = 0; i < mockThumbs.length; i++) {
            Map<String, Object> video = new HashMap<>();
            video.put("id", "v_" + soundId + "_" + (i + 1));
            video.put("thumbnailUrl", mockThumbs[i]);
            video.put("views", viewCounts[i]);
            video.put("soundId", soundId);
            video.put("soundTitle", sound.getTitle());
            videos.add(video);
        }

        return videos;
    }
}
