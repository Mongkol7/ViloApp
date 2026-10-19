package com.vilo.backend.service;

import com.vilo.backend.dto.HashtagResponse;
import com.vilo.backend.dto.SearchHistoryResponse;
import com.vilo.backend.dto.SearchSummaryResponse;
import com.vilo.backend.dto.SoundResponse;
import com.vilo.backend.dto.UserResponse;
import com.vilo.backend.entity.Hashtag;
import com.vilo.backend.entity.SearchHistory;
import com.vilo.backend.entity.Sound;
import com.vilo.backend.entity.User;
import com.vilo.backend.repository.HashtagRepository;
import com.vilo.backend.repository.SearchHistoryRepository;
import com.vilo.backend.repository.SoundRepository;
import com.vilo.backend.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class SearchService {

    private final UserRepository userRepository;
    private final SoundRepository soundRepository;
    private final HashtagRepository hashtagRepository;
    private final SearchHistoryRepository searchHistoryRepository;

    public SearchService(UserRepository userRepository,
                         SoundRepository soundRepository,
                         HashtagRepository hashtagRepository,
                         SearchHistoryRepository searchHistoryRepository) {
        this.userRepository = userRepository;
        this.soundRepository = soundRepository;
        this.hashtagRepository = hashtagRepository;
        this.searchHistoryRepository = searchHistoryRepository;
    }

    @Transactional
    public SearchSummaryResponse search(String query, String type, String username) {
        String trimmed = query != null ? query.trim() : "";
        String normalizedType = type != null ? type.toUpperCase() : "ALL";

        SearchSummaryResponse response = new SearchSummaryResponse(trimmed, normalizedType);

        // Record search history if authenticated and query is not empty
        if (username != null && !trimmed.isEmpty()) {
            userRepository.findByUsername(username).ifPresent(user -> {
                SearchHistory history = new SearchHistory(user, trimmed, normalizedType);
                searchHistoryRepository.save(history);
            });
        }

        // Return empty or trending if query is blank
        if (trimmed.isEmpty()) {
            return getTrendingExplore();
        }

        // 1. Search Users
        if ("ALL".equals(normalizedType) || "USERS".equals(normalizedType)) {
            String userQuery = trimmed.replaceAll("^@+", "").trim();
            List<User> users = userQuery.isEmpty()
                    ? userRepository.findAll(PageRequest.of(0, 10)).getContent()
                    : userRepository.searchUsers(userQuery, PageRequest.of(0, 10));
            List<UserResponse> userDtos = users.stream()
                    .map(UserResponse::fromEntitySummary)
                    .collect(Collectors.toList());
            response.setUsers(userDtos);
        }

        // 2. Search Sounds
        if ("ALL".equals(normalizedType) || "SOUNDS".equals(normalizedType)) {
            String soundQuery = trimmed.replaceAll("^[#@]+", "").trim();
            List<Sound> sounds = soundRepository.searchSounds(soundQuery, PageRequest.of(0, 10));
            List<SoundResponse> soundDtos = sounds.stream()
                    .map(SoundResponse::fromEntity)
                    .collect(Collectors.toList());
            response.setSounds(soundDtos);
        }

        // 3. Search Hashtags
        if ("ALL".equals(normalizedType) || "HASHTAGS".equals(normalizedType)) {
            String tagQuery = trimmed.replaceAll("^#+", "").trim();
            List<Hashtag> hashtags = tagQuery.isEmpty()
                    ? hashtagRepository.findAll(PageRequest.of(0, 10)).getContent()
                    : hashtagRepository.searchHashtags(tagQuery, PageRequest.of(0, 10));
            List<HashtagResponse> tagDtos = hashtags.stream()
                    .map(HashtagResponse::fromEntity)
                    .collect(Collectors.toList());
            response.setHashtags(tagDtos);
        }

        // 4. Trending Videos matching query
        if ("ALL".equals(normalizedType) || "VIDEOS".equals(normalizedType)) {
            String videoQuery = trimmed.replaceAll("^[#@]+", "").trim();
            response.setTrendingVideos(getSampleMatchingVideos(videoQuery));
        }

        return response;
    }

    @Transactional(readOnly = true)
    public SearchSummaryResponse getTrendingExplore() {
        SearchSummaryResponse summary = new SearchSummaryResponse("", "EXPLORE");

        // Top trending hashtags
        List<Hashtag> trendingTags = hashtagRepository.findByIsTrendingTrueOrderByUsageCountDesc();
        if (trendingTags.isEmpty()) {
            trendingTags = hashtagRepository.findAllByOrderByUsageCountDesc(PageRequest.of(0, 8));
        }
        summary.setHashtags(trendingTags.stream().map(HashtagResponse::fromEntity).collect(Collectors.toList()));

        // Top trending sounds
        List<Sound> trendingSounds = soundRepository.findByIsTrendingTrueOrderByUsageCountDesc();
        if (trendingSounds.isEmpty()) {
            trendingSounds = soundRepository.findAllByOrderByUsageCountDesc(PageRequest.of(0, 5));
        }
        summary.setSounds(trendingSounds.stream().map(SoundResponse::fromEntity).collect(Collectors.toList()));

        // Trending video grid
        summary.setTrendingVideos(getDefaultTrendingVideos());

        return summary;
    }

    @Transactional(readOnly = true)
    public List<SearchHistoryResponse> getSearchHistory(String username) {
        if (username == null) return Collections.emptyList();
        return userRepository.findByUsername(username)
                .map(user -> searchHistoryRepository.findByUserOrderByCreatedAtDesc(user, PageRequest.of(0, 15))
                        .stream()
                        .map(SearchHistoryResponse::fromEntity)
                        .collect(Collectors.toList()))
                .orElse(Collections.emptyList());
    }

    @Transactional
    public void clearSearchHistory(String username) {
        if (username != null) {
            userRepository.findByUsername(username).ifPresent(searchHistoryRepository::deleteByUser);
        }
    }

    @Transactional
    public void deleteSearchHistoryItem(String username, Long id) {
        if (username != null && id != null) {
            userRepository.findByUsername(username).ifPresent(user -> searchHistoryRepository.deleteByIdAndUser(id, user));
        }
    }

    private List<Map<String, Object>> getDefaultTrendingVideos() {
        List<Map<String, Object>> videos = new ArrayList<>();
        String[] thumbs = {
                "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80",
                "https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80"
        };
        String[] views = {"2.4M", "940K", "1.1M", "482K", "1.7M", "820K", "280K", "195K"};
        String[] titles = {
                "Tokyo Cyberpunk Night",
                "Retro Synth Wave",
                "Flutter 3.x Liquid Glass",
                "Urban Flow Beats",
                "Future Neon Horizon",
                "Lo-Fi Coding Session",
                "Aesthetic Morning Routine & Studio Vlog",
                "Minimalist Architecture Walk"
        };
        String[] authors = {"noir_pulse", "bunheng", "mongkol", "rithysak", "mongkol", "mongkol", "kimliza", "trenmono"};
        String[] authorNames = {
                "Noir Pulse",
                "Lim Bunheng",
                "Thoeung Sereymongkol",
                "Chhuon Rithysak",
                "Thoeung Sereymongkol",
                "Thoeung Sereymongkol",
                "Kim Liza",
                "Tren Mono"
        };

        for (int i = 0; i < thumbs.length; i++) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", "trend_" + (i + 1));
            map.put("thumbnailUrl", thumbs[i]);
            map.put("views", views[i]);
            map.put("title", titles[i]);
            map.put("authorUsername", "@" + authors[i]);
            map.put("authorName", authorNames[i]);
            videos.add(map);
        }
        return videos;
    }

    private List<Map<String, Object>> getSampleMatchingVideos(String query) {
        String clean = query.replaceAll("^[#@]+", "").trim().toLowerCase();
        if (clean.isEmpty()) return getDefaultTrendingVideos();

        String cleanNorm = clean.replaceAll("[^a-z0-9]", "");
        String[] tokens = clean.split("[\\s_.-]+");
        List<Map<String, Object>> all = getDefaultTrendingVideos();

        return all.stream()
                .filter(v -> {
                    String title = String.valueOf(v.get("title")).toLowerCase();
                    String author = String.valueOf(v.getOrDefault("authorUsername", "")).toLowerCase().replaceAll("^@", "");
                    String authorName = String.valueOf(v.getOrDefault("authorName", "")).toLowerCase();
                    String combined = (title + " " + author + " " + authorName).toLowerCase();
                    String combinedNorm = combined.replaceAll("[^a-z0-9]", "");

                    if (combined.contains(clean) || (cleanNorm.length() >= 2 && combinedNorm.contains(cleanNorm))) {
                        return true;
                    }
                    for (String token : tokens) {
                        if (!token.isEmpty() && (combined.contains(token) || combinedNorm.contains(token))) {
                            return true;
                        }
                    }
                    return false;
                })
                .collect(Collectors.toList());
    }
}
