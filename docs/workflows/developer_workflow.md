# Developer & Testing Workflows

## 1. Local Development Setup
- **Flutter SDK**: `^3.12.2` or later.
- **Target Devices**:
  - Android Emulator (API 34+ recommended).
  - Physical Android / iOS devices.
  - Windows Desktop / Chrome / Edge.

### Essential Commands
```bash
# Get dependencies
flutter pub get

# Run app on connected emulator or device
flutter run

# Run static analysis
flutter analyze

# Run complete automated test suite
flutter test
```

---

## 2. Windows Multi-Root Drive Build Configuration
When developing on Windows where the Flutter Pub cache is located on drive `C:\` and the project workspace is on drive `D:\`, Kotlin incremental compilation may attempt multi-root file indexing.

The project is pre-configured with `incremental = false` in `android/build.gradle.kts` and `android/gradle.properties` to ensure 100% reliable builds:

```bash
# Clean build artifacts if needed
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug
```

---

## 3. Git & Commit Guidelines
Follow Conventional Commits format:
- `feat(inbox)`: New story features, trimmer, or viewer components
- `feat(profile)`: Profile thought balloon and state sync
- `feat(feed)`: Video player controls, pause overlays, or tab lifecycle
- `fix(build)`: Build script and compilation fixes
- `test(...)`: Unit and widget test suite updates
- `docs(...)`: Documentation updates

---

## 4. State Management Architecture: Thought Stories
The app uses a centralized singleton `ThoughtStoryManager` (`ValueNotifier<SharedThoughtStory?>`) located at `lib/features/inbox_activity/data/datasources/thought_story_manager.dart`:
- When a user shares a thought story from `InboxScreen` or `ProfileScreen`, calling `ThoughtStoryManager.instance.setStory(story)` notifies all subscribed screens.
- When a user deletes a story via `StoryViewerScreen`, calling `ThoughtStoryManager.instance.deleteStory()` cleans up the state and resets both avatars to the default unshared state simultaneously.
