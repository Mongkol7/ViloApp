# Vilo — Short-Form Video & E-Commerce Platform

**Vilo** is a modern full-stack mobile application built for high-performance short-form video discovery paired with an integrated e-commerce showcase. Designed with an Obsidian Pulse dark-first aesthetic, Vilo provides a seamless creator and consumer experience featuring continuous video feeds, dual media uploads (videos & photos), real-time profile grid synchronization, interactive thought stories with audio trimmer equalizers, and comprehensive creator profile and shopping hubs.

---

## 📱 Key Features

### 1. Short-Form Video Feed & Media Playback
- **Vertical Swipe Feed**: Infinite vertical video playback with ultra-smooth transitions and caching.
- **Intelligent Playback Lifecycle**:
  - **Center Pause Indicator**: Semi-transparent floating overlay when video is paused.
  - **Route-Aware Auto Pause/Resume**: Automatically pauses video playback when opening Search, Comments, or navigating away, and automatically resumes on return.
  - **Tab Switching Control**: Automatically stops video rendering when navigating to other bottom or top tabs to conserve system resources and battery.
  - **Continuous Looping**: Seamless, uninterrupted audio-video loop playback.
- **Interactive Overlay**: Double-tap like actions, bookmarking, animated sound disc, comments bottom sheet, and external share modal.
- **Multi-Tab Feed**: Top navigation bar supporting **Community** (explore grid), **Following**, **For You**, and **Shop** feeds with quick Search navigation.
- **Full-Screen Video Viewer**: Watch any video from creator profile grids or search results full-screen with native back button navigation.

### 2. Creator Media Upload Studio
- **Split Action Modal**: Fast access to Camera, Upload Video, and Upload Photo directly from the navigation shell.
- **Resilient Upload Pipeline**: Dual `ImagePicker` + `FilePicker` fallback with Android 13+ granular media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`).
- **Direct Disk Streaming**: Uses `http.MultipartFile.fromPath` direct disk streaming to avoid in-memory byte buffer allocation and prevent OutOfMemory crashes on large videos (up to 50MB+).
- **Dual Media Types**: Post vertical video media (`.mp4`, `.mov`, `.webm`) or photographic image posts (`.jpg`, `.png`, `.webp`) with custom captions, hashtag parsing, and thumbnail previews.

### 3. Creator Profile & Real-Time Sync
- **Instant Optimistic Prepending**: Uploaded videos instantly appear at index 0 of the profile grid without requiring an app reload or screen recreation via `ProfileSyncService.videoUploadedEvents`.
- **Decoupled Video Loading**: User video fetching from `/api/v1/videos/user/{id}` runs independently from auth `/users/me` calls, ensuring reliable display under any token state.
- **Pull-To-Refresh**: Integrated `RefreshIndicator` with `AlwaysScrollableScrollPhysics` across all profile tabs.
- **Dynamic Thumbnail Posters**: Automatically resolves backend paths (`/uploads/...`), renders images for photo posts, and generates dynamic posters for videos without explicit thumbnails.
- **5-Tab Content Hub**: 🎵 **Sounds**, 📹 **Postings**, 🛍️ **Shop**, 🔖 **Saved**, and ❤️ **Liked**.

### 4. Share Your Mind — Thought Stories System
- **Ephemeral Thought Sharing**: Floating thought speech balloons positioned on top of the user's avatar on both the Inbox and Profile screens.
- **Two-Way Real-Time State Synchronization**: Centralized state manager ensuring that sharing or deleting a thought story updates all app screens simultaneously.
- **Atmospheric Palette Switcher**: 6 themes (*Obsidian Dark, Midnight Violet, Crimson Dusk, Cyber Blue, Deep Emerald, Espresso Amber*).
- **Interactive Music Trimmer**:
  - Auto-scrolling featured music carousel.
  - Dynamic waveform visualizer with instantaneous reselection replay.
  - Clip duration scroll wheel ($5\text{s} - 60\text{s}$).
  - Live animated dancing music equalizer bars.
- **Fullscreen Story Viewer**: Story progress timer, views count inspector modal with follow toggles, and options menu to delete stories.

### 5. Friends & Social Discovery
- **Creator Recommendations**: Friend suggestions with one-tap Follow/Following and Remove interactions.
- **Universal Search & Trending**: 3-column video explore grid, trending creators, popular audio tracks, and persistent search history.

---

## 🛠️ Technology Stack & Architecture

- **Mobile Client**: [Flutter](https://flutter.dev/) (Channel stable, ^3.7.0+)
  - **Language**: [Dart](https://dart.dev/) 3.x
  - **Architecture**: Feature-Driven Layered Clean Architecture (`app/`, `core/`, `features/`).
  - **Video & Media**: `video_player` with hardware acceleration, `RouteObserver` lifecycle integration, and direct disk streaming multipart upload.
  - **Design System**: Obsidian Pulse Dark Canvas (`#080808` / `#141414`), Inter typography, and glassmorphism styling.
- **Backend Service**: [Spring Boot 3.4.1](https://spring.io/projects/spring-boot) (Java 17+)
  - **Security**: Spring Security 6 with stateless JWT Bearer token authentication.
  - **Persistence**: Spring Data JPA with PostgreSQL 18.
  - **Port**: Always runs on port `3000` (`http://localhost:3000/api/v1`).
  - **Media Serving**: Static WebMvc resource handler streaming `/uploads/**` directly from disk.
- **Database**: PostgreSQL 18 (`vilo_db` on port 5432).

---

## 📂 Project Structure

```
viloapp/
├── backend/                    # Spring Boot 3.4.1 REST API (Port 3000)
│   ├── src/main/java/com/vilo/backend/
│   │   ├── config/             # SecurityConfig (JWT), WebMvcConfig (/uploads/**), DataInitializer
│   │   ├── controller/         # Auth, User, Video, Search REST Controllers
│   │   ├── entity/             # User, Video, VideoLike, VideoSave, Comment, SearchHistory
│   │   ├── repository/         # Spring Data JPA Repositories
│   │   ├── security/           # JwtTokenProvider, JwtAuthenticationFilter
│   │   └── service/            # Business services and LocalFileStorageService
│   └── src/main/resources/     # application.properties (Port 3000, DB config)
├── uploads/                    # Local media storage directory (/uploads/videos, photos, thumbnails)
├── lib/
│   ├── app/                    # App root configuration, themes, and global RouteObserver
│   ├── core/                   # Shared design system, ApiClient, constants, and utilities
│   │   ├── constants/          # Design tokens and dimensions
│   │   ├── network/            # ApiClient (HTTP client, JWT injection, base URL auto-detection)
│   │   └── theme/              # Dark Obsidian theme and typography definitions
│   └── features/               # Independent modular feature slices
│       ├── auth/               # Login, Registration, and Password Reset screens
│       ├── bottom_nav/         # Scroll-aware floating bottom bar & main navigation shell
│       ├── feed/               # Video feed, UploadVideoSheet, comments sheet, sound details
│       ├── inbox_activity/     # Thought stories, music trimmer, viewer sheet & chats
│       ├── profile/            # ProfileScreen, PublicProfileScreen, Followers/Following, ProfileSyncService
│       ├── search_discover/    # Discover search bar, category chips, and trending grid
│       └── shop/               # Shop showcase, product details & cart
└── test/                       # 28 passing unit & widget tests
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured in your `PATH`.
- [JDK 17+](https://adoptium.net/) installed.
- PostgreSQL 18 running locally on port 5432 with database `vilo_db`.

### 2. Launch Backend (Port 3000)
```bash
cd backend
./mvnw spring-boot:run
```
Backend will start on `http://localhost:3000/api/v1` with Swagger docs available at `http://localhost:3000/swagger-ui.html`.

### 3. Run Flutter Application
```bash
flutter pub get
flutter run
```

### 4. Run Automated Test Suites
```bash
flutter test
```

---

## ✅ Quality Assurance & Verification
- **Static Analysis**: `flutter analyze` passing with 0 compilation errors.
- **Automated Tests**: 28 automated tests passing across `widget_test.dart`, `upload_video_sheet_test.dart`, and `profile_video_post_test.dart`.
