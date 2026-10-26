# Learned Quirks & Gotchas (Memory Log)

## 1. Android Emulator (QEMU on Windows) Memory Allocation

- **Symptom**: `pc_memory_init: above 4g size: 140000000` / emulator exit code 1 immediately after startup.
- **Cause**: Allocating $\ge 8\text{GB}$ RAM (`hw.ramSize=8192`) causes QEMU 64-bit address reservation conflicts on Windows host hypervisors.
- **Fix**: Set `hw.ramSize=2048` or `3072` in `~/.android/avd/Pixel_7_Pro.avd/config.ini`.

## 2. Touch Hit Targets & Compact States

- When scaling down navigation or list items in compact scroll states, always enforce `ConstrainedBox(constraints: BoxConstraints(minWidth: 44, minHeight: 44))` to preserve mobile accessibility standards.

## 3. Scroll Hysteresis Thresholds

- To avoid jitter during slow reading or micro-scrolling, require $\Delta y > 20\text{pt}$ for downward compaction, but allow immediate expansion on upward flick $\Delta y < -6\text{pt}$ or top bounce `offset <= 0`.

## 4. Android 13+ Granular Media Permissions

- **Symptom**: `Permission denied` or `MissingPluginException` when opening file picker on API 33+ devices.
- **Cause**: Android 13 deprecated `READ_EXTERNAL_STORAGE` in favor of `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, and `READ_MEDIA_VISUAL_USER_SELECTED`.
- **Fix**: Declare these permissions in `android/app/src/main/AndroidManifest.xml` and use `ImagePicker` as the primary picker with `FilePicker(withData: false)` as graceful fallback.

## 5. Large File Uploads & OOM Prevention

- **Symptom**: Flutter app crashes or hangs when picking or uploading high-resolution videos (20MB–50MB).
- **Cause**: Reading entire video byte arrays into memory (`file.readAsBytes()`) before constructing multipart requests leads to GC spikes and crashes.
- **Fix**: Pass the file path directly to `http.MultipartFile.fromPath('videoFile', filePath)` so the HTTP stream pumps directly from disk without buffer allocation.

## 6. NestedScrollView Pull-To-Refresh

- **Symptom**: Pulling down on profile grid does not trigger `RefreshIndicator`.
- **Cause**: Inner `CustomScrollView` inside `TabBarView` does not propagate overscroll notifications to the parent `NestedScrollView` unless configured with scrollable physics.
- **Fix**: Provide `physics: const AlwaysScrollableScrollPhysics()` to each tab's `CustomScrollView`.

## 7. Spring Boot Static File Serving (`WebMvcConfig`)

- **Symptom**: Uploaded video files return 404 when requested via `http://localhost:3000/uploads/videos/...`.
- **Cause**: In multi-module or project root setups, relative paths like `file:./uploads/` resolve relative to the current working directory, which may be `backend/` or the project root.
- **Fix**: In `WebMvcConfig.java`, specify multiple resource locations: `addResourceLocations(uploadUri, "file:./uploads/", "file:backend/uploads/")` and permit them in `SecurityConfig`.

## 8. Windows Port 3000 Clean-Up

- **Symptom**: `Failed to start bean 'webServerStartStop'` / `Port 3000 was already in use`.
- **Cause**: Orphaned background `java.exe` or node processes holding the TCP socket.
- **Fix**: Run `Get-NetTCPConnection -LocalPort 3000 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }` before launching the backend.

## 9. Flutter TabBarView NestedScrollView Initial Index Desync

- **Symptom**: Profile page loads with the second tab (Posted Videos, `initialIndex: 1`) highlighted in the `TabBar`, but the content shows Tab 0 (Music). Switching to another tab and back to Tab 1 fixes it.
- **Cause**: In `NestedScrollView`, the body viewport width is evaluated as `0.0` on the very first layout frame and during route animations. `PagePosition` clamps its scroll offset to `0.0`, discarding `initialPage: 1`. Because `TabController.index` is already 1, no animation tick is dispatched to `PageController`.
- **Fix**: Do NOT use arbitrary `_tabController.index = 0` hacks. Instead, use `ViloTabBarView` which wraps `PageView` and runs post-frame synchronization: if `pageController.page?.round() != controller.index`, it invokes `jumpToPage(controller.index)`.

## 10. Horizontal Scrollable TabBar Edge Fading

- **Symptom**: Tab labels are clipped sharply against container boundaries or refuse to drag horizontally when content fits within screen bounds.
- **Cause**: Default `TabBar` without explicit `labelPadding` fits within typical mobile widths, resulting in `maxScrollExtent == 0`.
- **Fix**: Use `labelPadding: const EdgeInsets.symmetric(horizontal: 20.0)` with `TabAlignment.center` and `BouncingScrollPhysics()` wrapped in `ShaderMask` with a linear alpha gradient (`stops: [0.0, 0.08, 0.92, 1.0]`).
