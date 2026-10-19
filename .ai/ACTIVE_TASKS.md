# Active Tasks & Roadmap Tracker

## Current Milestone: Full-Stack Video Engine, Media Upload & Live Social Synchronization

### Completed Tasks

- [x] **Project Architecture & Design System**:
  - Feature-Driven Layered Clean Architecture under `lib/` and Spring Boot 3.4.1 under `backend/`.
  - Obsidian Pulse design tokens (`PulseColors`, `PulseTypography`, `PulseSpacing`, `PulseRadius`).
  - Floating Liquid Glass Navigation Bar with 5-phase fluid spring transit physics & scroll-aware compaction.
- [x] **Backend Infrastructure (Spring Boot + PostgreSQL)**:
  - Spring Boot running on port 3000 with PostgreSQL 18 (`vilo_db` on port 5432).
  - Stateless JWT Authentication (Access + Refresh tokens) & Spring Security 6 with CORS/CSRF handling.
  - Video and User database schema (`videos`, `users`, `video_likes`, `video_saves`, `video_comments`, `followers_following`).
  - Static media resource streaming handler for `/uploads/**` (`uploads/videos`, `uploads/photos`, `uploads/thumbnails`).
- [x] **Short-Form Video Feed Engine & Interaction Polish (Member 2)**:
  - Vertical video `PageView.builder` supporting continuous scrolling with feed caching (`FeedRemoteDataSource`).
  - RouteAware video lifecycle auto-pause/resume and tab-switching resource saver.
  - Social interactions: Likes, saves/bookmarks, asynchronous view count incrementing, and live comments bottom sheet.
  - Animated Follow Button (`_AnimatedFollowButton`) featuring medium haptics, radial ripple shockwave burst, spring scale bounce (1.0 -> 1.42 -> 1.15), 180° rotation, color morph from `#FE2C55` to `#10B981`, and smooth checkmark morph with `easeInBack` exit.
  - Responsive Video Overlays: Dynamically computes bottom offsets (`infoBottom`, `actionButtonsBottom`, `dotsBottom`) to float cleanly above the floating bottom nav bar in main feeds (`padding.bottom + 80pt`) and hugs the bottom bezel in standalone profile viewers (`padding.bottom + 20pt`).
  - Edge-aligned right action controls (`right: 8`) and sound toggle button (`right: 8`) providing expansive horizontal breathing room for user captions and hashtags (`right: 70`).
  - Sound/mute button positioned below the top navbar category in main feeds (`padding.top + 64pt`) preventing overlap with the top category bar and search icon.
  - Top category navbar (`Community`, `Following`, `For You`, `Shop`) with `ShaderMask` horizontal edge alpha fading, `BouncingScrollPhysics`, `TabAlignment.center`, expanded tap hitboxes (`horizontal: 20pt`), and unselected tab opacity styling (`50%`).
- [x] **Media Upload Studio**:
  - Split action modal (Camera, Upload Video, Upload Photo).
  - Dual `ImagePicker` + `FilePicker` resilience pipeline with Android 13+ media permission support.
  - Direct disk streaming via `http.MultipartFile.fromPath` preventing in-memory byte buffer OOM crashes on large files.
  - Supports both video media formats (mp4, mov, webm, avi, mkv) and photo/image posts (jpg, png, webp, gif).
  - Rich hashtag parsing and clickable colored span rendering on posted feeds.
- [x] **Profile & Social Synchronization**:
  - Live broadcast bus via `ProfileSyncService.videoUploadedEvents`, `videoInteractionEvents`, `videoDeletedEvents`, and `followEvents`.
  - Instant optimistic prepending of uploaded videos to `_myVideos` on `ProfileScreen` upon posting.
  - Restricted video deletion strictly to user-owned posted videos viewed from the profile (`canDelete: true` on Tab 1 only), hiding it on saved, liked, public profiles, and news feeds.
  - Rock-solid tab synchronization using custom `ViloTabBarView` widget, resolving Flutter's `TabBarView` `initialIndex` zero-width layout desync bug.
  - Tab order aligned: Tab 0 = Music/Sounds (Left), Tab 1 = Posted Videos/Grid (Right of Music), Tab 2 = Shop, Tab 3 = Saved, Tab 4 = Liked.
  - Independent error boundaries in `_loadProfile()` ensuring user videos load from `/videos/user/{id}` even if token refresh is pending.
  - TabBarView `AlwaysScrollableScrollPhysics` with pull-to-refresh (`RefreshIndicator`).
  - Dynamic thumbnail resolution and click-to-watch full-screen playback via `VideoFeedPage`.
  - Thought stories system with 6 atmosphere palettes, music trimmer, viewer sheets, and synchronized deletion.
- [x] **Discovery & Search (Member 3)**:
  - Real-time search across Top, Accounts, Videos, Sounds, and Hashtags with search history persistence.
  - Full-text database search engine in `VideoRepository.searchVideos` matching video title, caption, hashtags, and creator username/displayName.
  - Automatic registration of hashtags on upload to `HashtagRepository` and `VideoTagRepository`.
  - Clickable search result video cards with instant playback in `VideoFeedPage`.
  - Multi-source local fallback search querying `FeedRemoteDataSource.getAllCachedVideos()` for offline resilience.
- [x] **Testing & Verification**:
  - Comprehensive suite of 28 passing unit and widget tests across all core features.
  - Clean `flutter analyze` with 0 errors across feed and profile features.

### Active & Next Roadmap Objectives

- [ ] Creator Studio Camera preview, live recording, and clip trimmer.
- [ ] Shop Showcase and e-commerce checkout integration.
- [ ] Direct messaging & real-time WebSocket chat enhancements.
- [ ] Push notifications pipeline for social interactions.
