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
import com.vilo.backend.entity.Video;
import com.vilo.backend.entity.VideoTag;
import com.vilo.backend.repository.HashtagRepository;
import com.vilo.backend.repository.SearchHistoryRepository;
import com.vilo.backend.repository.SoundRepository;
import com.vilo.backend.repository.UserRepository;
import com.vilo.backend.repository.VideoRepository;
import com.vilo.backend.repository.VideoTagRepository;
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
    private final VideoRepository videoRepository;
    private final VideoTagRepository videoTagRepository;

    public SearchService(UserRepository userRepository,
                         SoundRepository soundRepository,
                         HashtagRepository hashtagRepository,
                         SearchHistoryRepository searchHistoryRepository,
                         VideoRepository videoRepository,
                         VideoTagRepository videoTagRepository) {
        this.userRepository = userRepository;
        this.soundRepository = soundRepository;
        this.hashtagRepository = hashtagRepository;
        this.searchHistoryRepository = searchHistoryRepository;
        this.videoRepository = videoRepository;
        this.videoTagRepository = videoTagRepository;
    }

    @Transactional
    public SearchSummaryResponse search(String query, String type, String username) {
        String trimmed = query != null ? query.trim() : "";
        String normalizedType = type != null ? type.toUpperCase() : "ALL";

        SearchSummaryResponse response = new SearchSummaryResponse(trimmed, normalizedType);

        // Record search history if authenticated and query is not empty
        if (username != null && !trimmed.isEmpty()) {
            userRepository.findByUsername(username).ifPresent(user -> {
                recordSearch(user, trimmed, normalizedType);
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

            // User search also returns the public videos posted by the
            // matched accounts so the client can show them below the users.
            if ("USERS".equals(normalizedType) && !users.isEmpty()) {
                List<Map<String, Object>> userVideoDtos = videoRepository
                        .findByCreatorInOrderByCreatedAtDesc(users, PageRequest.of(0, 30))
                        .getContent()
                        .stream()
                        .map(this::convertVideoToMap)
                        .collect(Collectors.toList());
                response.setTrendingVideos(userVideoDtos);
            }
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

        // 3. Search Hashtags (from Hashtag entity + VideoTag table)
        if ("ALL".equals(normalizedType) || "HASHTAGS".equals(normalizedType)) {
            String tagQuery = trimmed.replaceAll("^#+", "").trim();
            List<Hashtag> hashtags = tagQuery.isEmpty()
                    ? hashtagRepository.findAll(PageRequest.of(0, 10)).getContent()
                    : hashtagRepository.searchHashtags(tagQuery, PageRequest.of(0, 10));
            List<HashtagResponse> tagDtos = hashtags.stream()
                    .map(HashtagResponse::fromEntity)
                    .collect(Collectors.toList());

            if (videoTagRepository != null && !tagQuery.isEmpty()) {
                Set<String> seenTags = tagDtos.stream()
                        .map(h -> h.getTag().toLowerCase())
                        .collect(Collectors.toSet());
                List<String> videoTags = videoTagRepository.searchTagNames(tagQuery, PageRequest.of(0, 10));
                for (String vt : videoTags) {
                    if (vt != null && !vt.isBlank() && seenTags.add(vt.toLowerCase())) {
                        HashtagResponse customTag = new HashtagResponse();
                        customTag.setTag(vt);
                        customTag.setFormattedTag("#" + vt);
                        customTag.setUsageCount(1L);
                        customTag.setFormattedUsageCount("1 post");
                        customTag.setIsTrending(false);
                        tagDtos.add(customTag);
                    }
                }
            }

            response.setHashtags(tagDtos);
        }

        // 4. Videos matching query (searches real DB videos by title, caption, hashtag, author)
        if ("ALL".equals(normalizedType) || "VIDEOS".equals(normalizedType)) {
            String videoQuery = trimmed.replaceAll("^[#@]+", "").trim();
            List<Map<String, Object>> videoDtos = new ArrayList<>();
            Set<Long> seenIds = new HashSet<>();

            if (!videoQuery.isEmpty()) {
                // 1. Primary phrase match
                List<Video> dbVideos = videoRepository.searchVideos(videoQuery, PageRequest.of(0, 30));
                for (Video v : dbVideos) {
                    if (seenIds.add(v.getId())) {
                        videoDtos.add(convertVideoToMap(v));
                    }
                }

                // 2. Tokenized search if multi-word query
                String[] tokens = videoQuery.split("[\\s_.-]+");
                if (tokens.length > 1) {
                    for (String token : tokens) {
                        if (token.length() >= 2) {
                            List<Video> tokenVideos = videoRepository.searchVideos(token, PageRequest.of(0, 15));
                            for (Video v : tokenVideos) {
                                if (seenIds.add(v.getId())) {
                                    videoDtos.add(convertVideoToMap(v));
                                }
                            }
                        }
                    }
                }
            }

            videoDtos.sort((left, right) -> Long.compare(
                    getViewCount(right),
                    getViewCount(left)
            ));
            response.setTrendingVideos(videoDtos);
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

        // Trending video grid (real database videos only)
        List<Video> trendingDbVideos = videoRepository.findAllByOrderByViewCountDesc(PageRequest.of(0, 20)).getContent();
        if (!trendingDbVideos.isEmpty()) {
            List<Map<String, Object>> exploreVideos = trendingDbVideos.stream()
                    .map(this::convertVideoToMap)
                    .collect(Collectors.toList());
            summary.setTrendingVideos(exploreVideos);
        } else {
            summary.setTrendingVideos(Collections.emptyList());
        }

        return summary;
    }

    private Map<String, Object> convertVideoToMap(Video v) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", String.valueOf(v.getId()));
        String title = v.getTitle() != null && !v.getTitle().isBlank() ? v.getTitle()
                : (v.getCaption() != null ? v.getCaption() : "");
        map.put("title", title);
        map.put("caption", v.getCaption() != null ? v.getCaption() : "");
        map.put("videoUrl", v.getVideoUrl() != null ? v.getVideoUrl() : "");
        map.put("thumbnailUrl", v.getThumbnailUrl() != null ? v.getThumbnailUrl() : (v.getVideoUrl() != null && !v.getVideoUrl().contains(",") ? v.getVideoUrl() : ""));
        Long viewCount = v.getViewCount();
        Long likeCount = v.getLikeCount();
        Long commentCount = v.getCommentCount();
        Long saveCount = v.getSaveCount();

        map.put("views", formatCount(viewCount));
        map.put("viewCount", viewCount != null ? viewCount : 0L);
        map.put("likeCount", likeCount != null ? likeCount : 0L);
        map.put("likesCount", likeCount != null ? likeCount : 0L);
        map.put("commentCount", commentCount != null ? commentCount : 0L);
        map.put("commentsCount", commentCount != null ? commentCount : 0L);
        map.put("saveCount", saveCount != null ? saveCount : 0L);
        map.put("savesCount", saveCount != null ? saveCount : 0L);
        map.put("musicTitle", v.getMusicTitle() != null ? v.getMusicTitle() : "Original Sound");

        if (v.getCreator() != null) {
            String u = v.getCreator().getUsername();
            map.put("authorUsername", u != null && u.startsWith("@") ? u : "@" + u);
            map.put("authorName", v.getCreator().getDisplayName() != null ? v.getCreator().getDisplayName() : u);
            map.put("creatorId", v.getCreator().getId());
            map.put("avatarUrl", v.getCreator().getAvatarUrl());
        } else {
            map.put("authorUsername", "@vilo");
            map.put("authorName", "Vilo Creator");
            map.put("creatorId", null);
            map.put("avatarUrl", null);
        }

        List<String> tagList = new ArrayList<>();
        if (v.getTags() != null) {
            for (VideoTag tag : v.getTags()) {
                if (tag != null && tag.getTagName() != null && !tag.getTagName().isBlank()) {
                    tagList.add(tag.getTagName());
                }
            }
        }
        map.put("tags", tagList);

        return map;
    }

    private String formatCount(Long count) {
        if (count == null || count <= 0) return "0";
        if (count >= 1_000_000) return String.format(Locale.US, "%.1fM", count / 1_000_000.0);
        if (count >= 1_000) return String.format(Locale.US, "%.1fK", count / 1_000.0);
        return String.valueOf(count);
    }

    private long getViewCount(Map<String, Object> video) {
        Object value = video.get("viewCount");
        return value instanceof Number ? ((Number) value).longValue() : 0L;
    }

    @Transactional
    public void recordSearch(User user, String query, String searchType) {
        if (user == null || query == null || query.trim().isEmpty()) return;
        String cleanQuery = query.trim();
        try {
            searchHistoryRepository.deleteByUserAndQuery(user, cleanQuery);
        } catch (Exception ignored) {}
        SearchHistory history = new SearchHistory(user, cleanQuery, searchType != null ? searchType : "ALL");
        searchHistoryRepository.save(history);
    }

    @Transactional
    public void recordSearchHistory(String username, String query, String searchType) {
        if (username != null && query != null && !query.trim().isEmpty()) {
            userRepository.findByUsername(username).ifPresent(user -> {
                recordSearch(user, query, searchType);
            });
        }
    }

    @Transactional(readOnly = true)
    public List<SearchHistoryResponse> getSearchHistory(String username) {
        if (username == null) return Collections.emptyList();
        return userRepository.findByUsername(username)
                .map(user -> {
                    List<SearchHistory> raw = searchHistoryRepository.findByUserOrderByCreatedAtDesc(user, PageRequest.of(0, 25));
                    Set<String> seen = new HashSet<>();
                    List<SearchHistoryResponse> result = new ArrayList<>();
                    for (SearchHistory sh : raw) {
                        String q = sh.getQuery().trim();
                        if (seen.add(q.toLowerCase())) {
                            result.add(SearchHistoryResponse.fromEntity(sh));
                        }
                    }
                    return result;
                })
                .orElse(Collections.emptyList());
    }

    @Transactional
    public void clearSearchHistory(String username) {
        if (username != null) {
            userRepository.findByUsername(username).ifPresent(searchHistoryRepository::deleteByUser);
        }
    }

    @Transactional
    public void deleteSearchHistoryByQuery(String username, String query) {
        if (username != null && query != null && !query.trim().isEmpty()) {
            userRepository.findByUsername(username).ifPresent(user -> {
                searchHistoryRepository.deleteByUserAndQuery(user, query.trim());
            });
        }
    }

    @Transactional
    public void deleteSearchHistoryItem(String username, Long id) {
        if (username != null && id != null) {
            userRepository.findByUsername(username).ifPresent(user -> searchHistoryRepository.deleteByIdAndUser(id, user));
        }
    }

}
