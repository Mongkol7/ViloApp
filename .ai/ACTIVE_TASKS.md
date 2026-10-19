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
- [x] **Short-Form Video Feed Engine (Member 2)**:
  - Vertical video `PageView.builder` supporting continuous scrolling with feed caching (`FeedRemoteDataSource`).
  - RouteAware video lifecycle auto-pause/resume and tab-switching resource saver.
  - Social interactions: Likes, saves/bookmarks, asynchronous view count incrementing, and live comments bottom sheet.
- [x] **Media Upload Studio**:
  - Split action modal (Camera, Upload Video, Upload Photo).
  - Dual `ImagePicker` + `FilePicker` resilience pipeline with Android 13+ media permission support.
  - Direct disk streaming via `http.MultipartFile.fromPath` preventing in-memory byte buffer OOM crashes on large files.
  - Supports both video media formats (mp4, mov, webm, avi, mkv) and photo/image posts (jpg, png, webp, gif).
- [x] **Profile & Social Synchronization**:
  - Live broadcast bus via `ProfileSyncService.videoUploadedEvents` and `followEvents`.
  - Instant optimistic prepending of uploaded videos to `_myVideos` on `ProfileScreen` upon posting.
  - Independent error boundaries in `_loadProfile()` ensuring user videos load from `/videos/user/{id}` even if token refresh is pending.
  - TabBarView `AlwaysScrollableScrollPhysics` with pull-to-refresh (`RefreshIndicator`).
  - Dynamic thumbnail resolution and click-to-watch full-screen playback via `VideoFeedPage`.
  - Thought stories system with 6 atmosphere palettes, music trimmer, viewer sheets, and synchronized deletion.
- [x] **Discovery & Search (Member 3)**:
  - Real-time search across Top, Accounts, Videos, Sounds, and Products with search history persistence.
- [x] **Testing & Verification**:
  - Comprehensive suite of 28 passing unit and widget tests across all core features.

### Active & Next Roadmap Objectives
- [ ] Creator Studio Camera preview, live recording, and clip trimmer.
- [ ] Shop Showcase and e-commerce checkout integration.
- [ ] Direct messaging & real-time WebSocket chat enhancements.
- [ ] Push notifications pipeline for social interactions.
