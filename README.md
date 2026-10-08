# Vilo — Short-Form Video & E-Commerce Mobile Application

**Vilo** is a modern Flutter mobile application built for high-performance short-form video discovery paired with an integrated e-commerce showcase. Designed with an Obsidian Pulse dark-first aesthetic, Vilo provides a seamless creator and consumer experience featuring continuous video feeds, interactive thought stories with audio trimmer equalizers, real-time cross-screen state synchronization, and comprehensive profile and shopping hubs.

---

## 📱 Key Features

### 1. Short-Form Video Feed & Media Playback
- **Vertical Swipe Feed**: Infinite vertical video playback with ultra-smooth 60/120 FPS transitions.
- **Intelligent Playback Lifecycle**:
  - **Center Pause Indicator**: Semi-transparent floating overlay when video is paused.
  - **Route-Aware Auto Pause/Resume**: Automatically pauses video playback when opening Search, Comments, or navigating away, and automatically resumes on return.
  - **Tab Switching Control**: Automatically stops video rendering when navigating to other bottom or top tabs to conserve system resources and battery.
  - **Non-Stop Continuous Looping**: Seamless, uninterrupted audio-video loop playback.
- **Interactive Overlay**: Double-tap like actions, bookmarking, animated sound disc, comments bottom sheet, and external share modal.
- **Multi-Tab Feed**: Top navigation bar supporting **Community** (staggered explore grid), **Following**, **For You**, and **Shop** feeds with quick Search navigation.

### 2. Share Your Mind — Thought Stories System
- **Ephemeral Thought Sharing**: Floating thought speech balloons positioned on top of the user's avatar on both the Inbox and Profile screens.
- **Two-Way Real-Time State Synchronization**: Centralized state manager ensuring that sharing or deleting a thought story updates all app screens simultaneously.
- **Atmospheric Palette Switcher**: 6 vibrant themes (*Obsidian Dark, Midnight Violet, Crimson Dusk, Cyber Blue, Deep Emerald, Espresso Amber*).
- **Interactive Music Trimmer**:
  - Auto-scrolling featured music carousel.
  - Dynamic waveform visualizer with instantaneous reselection replay.
  - Clip duration scroll wheel ($5\text{s} - 60\text{s}$).
  - Live animated dancing music equalizer bars.
- **Fullscreen Story Viewer**: Story progress timer, views count inspector modal with follow toggles, and options menu to delete stories.

### 3. Friends & Social Discovery
- **Creator Recommendations**: Friend suggestions with one-tap Follow/Following and Remove interactions.
- **Search & Trending Hub**: 3-column video explore grid, trending creators, and popular audio tracks.

### 4. Inbox & Direct Messaging
- **Notification Hub**: Activity alerts, new follower notifications, and system updates.
- **Direct Messaging**: Full 1-on-1 chat conversation interface with media and messaging support.

### 5. Creator Profile & Shop Integration
- **Profile Header**: Avatar with active sunset gradient story ring, stats row (*Following, Followers, Likes*), and interactive bio.
- **5-Tab Content Hub**:
  1. 🎵 **Sounds**: Creator sound tracks with usage analytics.
  2. 📹 **Postings**: 3-column video thumbnail grid.
  3. 🛍️ **Shop**: Product catalog cards with instant price tags.
  4. 🔖 **Saved**: Bookmarked videos and audio.
  5. ❤️ **Liked**: Favorited video collection.
- **Shop & Product Details**: Integrated product showcase, cart management, and product detail views.

---

## 🛠️ Technology Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Channel stable, ^3.12.2+)
- **Language**: [Dart](https://dart.dev/) 3.x
- **Architecture**: Feature-Driven Layered Clean Architecture
  - `core/`: Shared constants, themes, typography, and reusable UI components.
  - `features/`: Vertical feature slices (`auth`, `feed`, `inbox_activity`, `profile`, `search_discover`, `shop`, `bottom_nav`).
- **Video & Media**: `video_player` with hardware acceleration, `RouteObserver` lifecycle integration, and custom Canvas waveform painters.
- **Design System**: Obsidian Dark Canvas (`#080808` / `#141416`), Inter typography, and glassmorphism styling.

---

## 📂 Project Structure

```
lib/
├── app/                        # App root configuration, themes, and global RouteObserver
├── core/                       # Shared design system, constants, and utilities
│   ├── constants/              # App colors, spacing tokens, and dimensions
│   └── theme/                  # Dark Obsidian theme and typography definitions
├── features/                   # Independent modular feature slices
│   ├── auth/                   # Login, Registration, and Password Reset screens
│   ├── bottom_nav/             # Scroll-aware floating bottom bar & main shell
│   ├── feed/                   # Home feed, video player, sound details & comments
│   ├── inbox_activity/         # Thought stories, music trimmer, viewer & chats
│   ├── profile/                # User profile, friends suggestions & tab slivers
│   ├── search_discover/        # Discover search bar and trending grid
│   └── shop/                   # Shop showcase, product details & cart
└── main.dart                   # Application entry point
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured in your `PATH`.
- Android Studio / VS Code with Flutter extensions.
- Android Emulator or physical device.

### Installation & Run

1. **Clone or extract the repository**:
   ```bash
   cd viloapp
   ```

2. **Install project dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

4. **Run automated test suites**:
   ```bash
   flutter test
   ```

---

## ✅ Quality Assurance & Verification
- **Static Analysis**: `flutter analyze` passing with zero compilation errors.
- **Automated Tests**: 100% test pass rate covering floating navigation bars, search routing, message threads, full story lifecycles, and profile state synchronization.
