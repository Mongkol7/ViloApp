# Vilo Release Notes & Milestone Log

---

## [v1.2.0] — Feed & Profile Polish, Fluid Gestures & Dynamic Animations

### 🚀 Highlights & Features

1. **Dynamic Animated Follow Button**:
   - Upgraded the creator avatar follow badge from a static icon to a multi-stage spring physics animation (`_AnimatedFollowButton`).
   - Includes haptic vibration feedback, expanding shockwave ripple ring, elastic pop scaling, 180° rotation, color morphing from crimson to emerald, and a smooth icon transition into a rounded checkmark (`✓`) before fading away into the avatar.

2. **Responsive Video Overlay Layout Engine**:
   - Added context-aware positioning calculations based on `isStandalone`.
   - **Main News Feed**: Account info, captions, and music title float at `padding.bottom + 80pt`, sitting just above the floating bottom navigation bar.
   - **Standalone Fullscreen Viewers** (opened from user profile, sound page, or search): Overlays move down to `padding.bottom + 20pt` with maximum viewing area.
   - Multi-image pagination dots automatically adapt their position (`dotsBottom = 175pt` vs `235pt`) to prevent overlap with multi-line captions.

3. **Edge-Aligned Controls & Sound Button Repositioning**:
   - Right-side interaction column (`Profile`, `Like`, `Comment`, `Save`, `Share`, `Music Disc`, `Delete`) moved to `right: 8` for an edge-aligned TikTok/Reels aesthetic.
   - Expanded caption text boundary to `right: 70` for generous horizontal reading space.
   - Repositioned the floating volume/mute icon on news feeds to `padding.top + 64pt`, cleanly clearing the category tab bar and search button.

4. **Top Category Navbar Edge Fading & Fluid Scrolling**:
   - Wrapped the top categories (`Community`, `Following`, `For You`, `Shop`) with a horizontal `ShaderMask` linear alpha gradient (`stops: [0.0, 0.08, 0.92, 1.0]`), making categories at the left and right edges smoothly fade into transparency.
   - Added `TabAlignment.center`, `BouncingScrollPhysics`, and `labelPadding: horizontal: 20pt` with touch, trackpad, and mouse drag support.
   - Inactive tabs styled with 50% opacity (`Colors.white.withValues(alpha: 0.50)`) for crisp visual hierarchy.

5. **Profile Tab Ordering & Synchronization (`ViloTabBarView`)**:
   - Re-aligned tab structure: **Tab 0 = Music/Sounds (Left)**, **Tab 1 = Posted Videos/Grid (Right of Music)**, followed by Shop, Saved, and Liked.
   - Developed `ViloTabBarView` to replace Flutter's native `TabBarView`, solving the long-standing bug where zero-width viewport initialization during `Navigator.push` route animations forced `initialIndex: 1` back to `page: 0` (Music).
   - Profiles now open directly to user posted videos across all profiles (current user and searched accounts).

6. **Restricted Video Deletion**:
   - Restricted deletion permissions strictly to user-owned videos opened from the user's profile posted video tab (`canDelete: true` passed only on Tab 1 in `ProfileScreen`).
   - Hidden across general news feed, saved videos, liked videos, and public profiles.

7. **Full-Text Database Video Title & Hashtag Search Engine**:
   - Replaced static mockup video searching in backend `SearchService` with real PostgreSQL queries against `VideoRepository.searchVideos`.
   - Searches across video `title`, `caption`, `description`, `VideoTag.tagName`, and creator username/displayName.
   - Automatically synchronizes video hashtags upon upload into `HashtagRepository` with incremented usage counts.
   - Enhanced Flutter `TrendingVideo` with full playback metadata and `toVideoModel()`, turning search grid cards into click-to-play viewers via `VideoFeedPage`.
   - Empowered client-side `_fallbackLocalSearch` to search `FeedRemoteDataSource.getAllCachedVideos()` for offline and local responsiveness.

8. **Purged Mock Video Data & Artificial Counters**:
   - Removed all 37 pre-seeded mock videos with inflated fake like counts (thousands "K" / millions "M") from the PostgreSQL database (`videos`).
   - Cleaned `DataInitializer.java` to prevent auto-seeding mock videos with artificial counts and added startup purge routines for any legacy mock rows.
   - Initialized new entity `Video.viewCount` to `0L` instead of synthetic `1000L` offset.
   - Cleared `StaticSearchData.trendingVideos` mockup data and removed hardcoded `"2.4M"`, `"940K"` fallback lists from `SearchService.java`.
   - Reset client fallback feed counters in `FeedRemoteDataSource._getFallbackFeed` and `ProfileMockData` to authentic baseline `0`.

---

## [v1.1.0] — Full-Stack Media Upload & Profile Sync

- Split action modal (Camera, Upload Video, Upload Photo).
- Dual `ImagePicker` + `FilePicker` resilience pipeline with Android 13+ media permission support.
- Direct disk streaming via `http.MultipartFile.fromPath` preventing in-memory byte buffer OOM crashes on large files.
- Live broadcast bus via `ProfileSyncService.videoUploadedEvents` and `followEvents`.
- Real-time search across Top, Accounts, Videos, Sounds, and Products with persistent history.
