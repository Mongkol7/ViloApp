# Vilo Application Features Specification

This document details the functional specifications and interaction models for key feature modules in Vilo.

---

## 1. Share Your Mind & Thought Stories System

### Overview
Users can share ephemeral thoughts with custom atmospheric palettes, attached trimmed music, and animated equalizers. Stories are accessible and synchronized between both the **Inbox Page** and the **Profile Page**.

### Flow & Components:
1. **Thought Balloon Entry**:
   - Floating speech bubble with `"Share a thought..."` and speech pointer positioned on top of the user's avatar on both `InboxScreen` and `ProfileScreen`.
   - Tapping opens `ShareThoughtScreen`.
2. **Share Thought Composer (`ShareThoughtScreen`)**:
   - Centered profile avatar layout.
   - **Atmospheric Palette Switcher**: Palette icon cycles through 6 themes (`Obsidian Dark`, `Midnight Violet`, `Crimson Dusk`, `Cyber Blue`, `Deep Emerald`, `Espresso Amber`).
   - **Music Attachment**: Music note icon opens the `MusicPickerBottomSheet`.
   - **Audio Equalizer Badge**: Once attached, displays track title with dancing equalizer bars.
3. **Music Picker (`MusicPickerBottomSheet`)**:
   - Auto-scrolling featured tracks carousel (3.2s interval with indicator dots).
   - Category tabs and search bar.
   - Tapping any track opens the `MusicTrimmerBottomSheet`.
4. **Music Trimmer (`MusicTrimmerBottomSheet`)**:
   - **Reselection Instant Replay**: Adjusting or scrolling the waveform immediately resets playhead and restarts audio from the start of the selected clip.
   - **Clip Duration Scroll Wheel**: Instagram-style duration selector ($5\text{s} - 60\text{s}$) with "Done" confirmation.
   - **Dynamic Window Sizing**: Trimmer selection box dynamically scales depending on chosen clip length.
   - **Synchronized Playhead & Progress Fill**: Waveform selection fill moves in lockstep with the playback slider.
5. **Story Viewer (`StoryViewerScreen`)**:
   - Fullscreen presentation with progress timer bar, custom background theme, and music badge with audio waveform.
   - Bottom-left `418 views` button opens the **Story Viewers** bottom sheet.
   - Bottom-right `⋮` icon opens the **Options Menu** with a **"Delete story"** action that removes the story in memory and updates both Profile and Inbox screens.
6. **Story Viewers Bottom Sheet (`StoryViewersBottomSheet`)**:
   - Modal sheet with total views count, search bar, and viewer list with interactive Follow/Following toggles.

---

## 2. Short-Form Video Feed & Playback Lifecycle

### Overview
Vertical short-form video feed with seamless tab navigation and playback control.

### Flow & Components:
1. **Top Feed Tabs (`HomeFeedPage`)**:
   - 4 tabs: `Community`, `Following`, `For You`, `Shop`.
   - `🔍` Search button in top-right routes directly to `SearchScreen`.
2. **Video Playback Lifecycle (`VideoFeedPage`)**:
   - **Center Pause Overlay**: Semi-transparent circular indicator (`Icons.play_arrow_rounded`) appears in the center of the video frame when playback is paused.
   - **RouteAware Auto-Pause/Resume**: When navigating to Search, Comments, or external screens, active video pauses automatically; upon returning, it resumes without requiring a tap.
   - **Tab Switching Control**: Switching to other bottom navigation tabs (Friends, Inbox, Profile) or inactive top feed tabs immediately pauses all background video rendering and playback.
   - **App Lifecycle**: Video pauses on app minimize and resumes on foregrounding.
   - **Dedicated Fullscreen Video Mode**: Supports `initialVideos` and `initialIndex` with a top-left back button for instant video viewing from profile grids and search results.

---

## 3. Creator Media Upload Studio (`UploadVideoSheet`)

### Overview
Fast and resilient media upload studio supporting both vertical videos and photographic posts.

### Flow & Components:
1. **Entry**:
   - Tapping the `+` button in `MainNavigationShell` triggers the Split Action Modal: Camera, Upload Video, or Upload Photo.
2. **Media Selection & Permission Resilience**:
   - Dual-engine picker: Primary `ImagePicker` + fallback `FilePicker(withData: false)`.
   - Full support for Android 13+ granular media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`).
   - Direct streaming disk multipart upload (`http.MultipartFile.fromPath`) bypassing in-memory buffer allocation to prevent OutOfMemory crashes on large videos.
3. **Metadata & Preview**:
   - Video / Photo preview tile with file name and size indicators.
   - Optional thumbnail picker for video posts.
   - Caption input and comma/space hashtag tag extractor.
4. **Post Completion & Broadcast**:
   - On successful HTTP upload to `/api/v1/videos/upload`, the resulting `VideoModel` is broadcasted immediately to:
     - `VideoFeedManager.instance.prependVideo(newVideo)`: Appears at index 0 of Home Feed.
     - `ProfileSyncService.instance.notifyVideoUploaded(newVideo)`: Prepend immediately to Profile screen grid.

---

## 4. Profile Screen & Public Creator View (`ProfileScreen` & `PublicProfileScreen`)

### Overview
Dynamic profile page managing user identity, posted media grid, social follower counts, and settings.

### Flow & Components:
1. **User Identity & Ephemeral Story Balloon**:
   - Displays avatar with **Share Your Mind** floating thought bubble and sunset gradient ring.
   - Displays display name, `@username`, verified badge, followers count, following count, and bio.
   - Followers/Following counts update optimistically in real-time on follow/unfollow events via `ProfileSyncService.followEvents`.
2. **Content Tabs**:
   - 5 tabs: `Music`, `Grid` (Postings), `Shop`, `Saved`, and `Liked`.
3. **Real-Time Video Sync & Grid Rendering**:
   - `ProfileScreen` listens to `ProfileSyncService.videoUploadedEvents`: Newly posted videos appear at index 0 immediately without requiring an app reload or tab recreation.
   - Decoupled `_loadProfile()`: User videos from `/api/v1/videos/user/{id}` load independently from auth `/users/me` profile calls.
   - Pull-To-Refresh: Equipped with `RefreshIndicator` and `AlwaysScrollableScrollPhysics` across all sliver tabs.
4. **Dynamic Thumbnail Resolution & Click-To-Watch**:
   - Resolves relative backend paths (`/uploads/videos/...`, `/uploads/photos/...`).
   - Photo posts automatically use their image as thumbnail.
   - Videos without thumbnails display unique dynamic posters.
   - Tapping any grid item opens `VideoFeedPage` full-screen at that exact index, with playback and back button navigation.

---

## 5. Friends / People Page (`PeopleScreen`)

- Displays creator suggestions with Follow/Follow back toggles and Remove actions.
- Top search icon routes to `SearchScreen`.
- Top-left menu icon is dedicated as a non-redirecting static interface element.

---

## 6. Search & Discover Screen (`SearchScreen`)

- Search input with clear button and live query execution.
- Category tabs: `Top`, `Accounts`, `Videos`, `Sounds`, `Shop`.
- Persistent search history with item deletion and "Clear all" capabilities.
- Direct navigation to `PublicProfileScreen` and `SoundDetailPage`.
