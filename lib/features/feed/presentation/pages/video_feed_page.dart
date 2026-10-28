import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/app.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_model.dart';
import '../controllers/video_feed_manager.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/video_likes_bottom_sheet.dart';
import 'sound_detail_page.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../search_discover/presentation/pages/search_screen.dart';

class VideoFeedPage extends StatefulWidget {
  final int? initialVideoId;
  final bool isActive;
  final int initialPage;
  final int initialIndex;
  final bool openCommentsOnStart;
  final String? initialCommentReplyUser;
  final String? initialCommentUserAvatar;
  final String? initialCommentText;
  final bool openLikesOnStart;
  final List<String>? initialLikeUserNames;
  final List<String>? initialLikeUserAvatars;
  final bool isStandalone;
  final String feedType; // 'FOR_YOU' or 'FOLLOWING'
  final int refreshToken;
  final List<VideoModel>? initialVideos;
  final bool canDelete;
  final bool? hasBottomNav;

  const VideoFeedPage({
    super.key,
    this.initialVideoId,
    this.isActive = true,
    this.initialPage = 0,
    this.initialIndex = 0,
    this.openCommentsOnStart = false,
    this.initialCommentReplyUser,
    this.initialCommentUserAvatar,
    this.initialCommentText,
    this.openLikesOnStart = false,
    this.initialLikeUserNames,
    this.initialLikeUserAvatars,
    this.isStandalone = false,
    this.feedType = 'FOR_YOU',
    this.refreshToken = 0,
    this.initialVideos,
    this.canDelete = false,
    this.hasBottomNav,
  });

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> with AutomaticKeepAliveClientMixin {
  static final Map<String, int> _savedPageIndices = {};

  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource.instance;
  late int _currentPage;
  late PageController _pageController;

  List<VideoModel> _videos = [];
  final List<VideoModel> _forYouReplayPool = [];
  bool _isLoading = true;
  int _apiPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isRecyclingForYou = false;
  int? _feedSeed;

  // Keep only the next couple of controllers warm. This avoids opening a
  // connection for every item in a long feed while making the next swipe
  // ready before it becomes visible.
  static const int _prefetchWindow = 2;
  final Map<int, Future<VideoPlayerController?>> _prefetchingControllers = {};
  final Map<int, VideoPlayerController> _prefetchedControllers = {};
  final Set<int> _builtVideoIds = {};
  bool _prefetchScheduled = false;
  int _prefetchGeneration = 0;

  @override
  bool get wantKeepAlive => true;

  bool get _isForYouFeed =>
      widget.initialVideos == null &&
      widget.feedType.toUpperCase().replaceAll('_', '') == 'FORYOU';

  @override
  void initState() {
    super.initState();
    _feedSeed = DateTime.now().millisecondsSinceEpoch;
    final startIdx = widget.initialVideos != null
        ? widget.initialIndex
        : (widget.initialPage != 0 ? widget.initialPage : widget.initialIndex);
    if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) {
      _videos = List.from(widget.initialVideos!);
      _isLoading = false;
      int matchIdx = -1;
      if (widget.initialVideoId != null) {
        matchIdx = _videos.indexWhere((v) => v.id == widget.initialVideoId);
      }
      _currentPage = (matchIdx != -1 ? matchIdx : startIdx).clamp(0, _videos.length - 1);
      _pageController = PageController(initialPage: _currentPage);
      _hasMore = false;
      _scheduleVideoPrefetch();
    } else {
      // Instant zero-latency display if feed is already in memory cache
      final cached = _dataSource.getCachedFeed(widget.feedType);
      if (cached != null && cached.isNotEmpty) {
        _videos = List.from(cached);
        _addToForYouReplayPool(cached);
        _isLoading = false;
      }

      // If a specific video is requested, ensure it is in _videos immediately
      if (widget.initialVideoId != null && !_videos.any((v) => v.id == widget.initialVideoId)) {
        final allCached = _dataSource.getAllCachedVideos();
        final match = allCached.where((v) => v.id == widget.initialVideoId).firstOrNull;
        if (match != null) {
          _videos.insert(0, match);
          _isLoading = false;
        } else {
          final fallback = _dataSource.getFallbackVideos();
          final matchFb = fallback.where((v) => v.id == widget.initialVideoId).firstOrNull;
          if (matchFb != null) {
            _videos.insert(0, matchFb);
            _isLoading = false;
          }
        }
      }

      int matchIdx = -1;
      if (widget.initialVideoId != null && _videos.isNotEmpty) {
        matchIdx = _videos.indexWhere((v) => v.id == widget.initialVideoId);
      }
      _currentPage = matchIdx != -1 ? matchIdx : (startIdx != 0 ? startIdx : (_savedPageIndices[widget.feedType] ?? 0));
      _pageController = PageController(initialPage: _currentPage);

      _fetchFeed(refresh: true);
    }

    if (widget.openCommentsOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentVideo = _videos.isNotEmpty && _currentPage < _videos.length
            ? _videos[_currentPage]
            : null;
        final effectiveVideo = (widget.initialVideoId != null)
            ? _videos.cast<VideoModel?>().firstWhere(
                (v) => v?.id == widget.initialVideoId,
                orElse: () => currentVideo,
              )
            : currentVideo;
        final targetVidId = widget.initialVideoId ?? effectiveVideo?.id;
        if (targetVidId != null) {
          VideoLikesBottomSheet.show(
            context,
            videoId: targetVidId,
            videoCreatorId: effectiveVideo?.creatorId,
            videoCreatorUsername: effectiveVideo?.username,
            initialCommentCount: effectiveVideo?.commentCount ?? 0,
            initialLikeCount: effectiveVideo?.likeCount ?? 0,
            initialTab: 0,
            initialReplyTo: widget.initialCommentReplyUser,
            initialCommentUserAvatar: widget.initialCommentUserAvatar,
            highlightCommentText: widget.initialCommentText,
          );
        }
      });
    }

    if (widget.openLikesOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentVideo = _videos.isNotEmpty && _currentPage < _videos.length
            ? _videos[_currentPage]
            : null;
        final effectiveVideo = (widget.initialVideoId != null)
            ? _videos.cast<VideoModel?>().firstWhere(
                (v) => v?.id == widget.initialVideoId,
                orElse: () => currentVideo,
              )
            : currentVideo;
        final targetVidId = widget.initialVideoId ?? effectiveVideo?.id;
        if (targetVidId != null) {
          VideoLikesBottomSheet.show(
            context,
            videoId: targetVidId,
            initialLikeCount: effectiveVideo?.likeCount ?? 0,
            initialCommentCount: effectiveVideo?.commentCount ?? 0,
            initialUserNames: widget.initialLikeUserNames,
            initialUserAvatars: widget.initialLikeUserAvatars,
            initialTab: 1,
          );
        }
      });
    }

    ProfileSyncService.instance.followEvents.addListener(_onGlobalFollowChanged);
    ProfileSyncService.instance.videoInteractionEvents.addListener(_onGlobalVideoInteraction);
    ProfileSyncService.instance.videoDeletedEvents.addListener(_onGlobalVideoDeleted);
    VideoFeedManager.instance.latestUploadedVideoNotifier.addListener(_onNewVideoUploaded);
  }

  @override
  void didUpdateWidget(covariant VideoFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _clearPrefetchCache();
      _currentPage = 0;
      _savedPageIndices[widget.feedType] = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _fetchFeed(refresh: true);
    } else if (oldWidget.feedType != widget.feedType) {
      _clearPrefetchCache();
      _feedSeed = DateTime.now().millisecondsSinceEpoch;
      _currentPage = _savedPageIndices[widget.feedType] ?? 0;
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
      _fetchFeed(refresh: true);
    } else if (oldWidget.isActive != widget.isActive) {
      setState(() {});
      if (widget.isActive && _videos.isNotEmpty && _currentPage < _videos.length) {
        _recordView(_videos[_currentPage].id);
      }
    }
  }

  @override
  void dispose() {
    VideoFeedManager.instance.latestUploadedVideoNotifier.removeListener(_onNewVideoUploaded);
    ProfileSyncService.instance.videoDeletedEvents.removeListener(_onGlobalVideoDeleted);
    ProfileSyncService.instance.videoInteractionEvents.removeListener(_onGlobalVideoInteraction);
    ProfileSyncService.instance.followEvents.removeListener(_onGlobalFollowChanged);
    _clearPrefetchCache();
    _pageController.dispose();
    super.dispose();
  }

  void _onGlobalVideoDeleted() {
    if (!mounted) return;
    final deletedId = ProfileSyncService.instance.videoDeletedEvents.value;
    if (deletedId == null) return;
    setState(() {
      _videos.removeWhere((v) => v.id == deletedId);
      _forYouReplayPool.removeWhere((v) => v.id == deletedId);
      if (_currentPage >= _videos.length && _videos.isNotEmpty) {
        _currentPage = _videos.length - 1;
      }
    });
  }

  void _onGlobalVideoInteraction() {
    if (!mounted) return;
    final event = ProfileSyncService.instance.videoInteractionEvents.value;
    if (event == null) return;

    final index = _videos.indexWhere((v) => v.id == event.videoId);
    if (index != -1) {
      final current = _videos[index];
      final updated = current.copyWith(
        isLiked: event.isLiked,
        likeCount: event.likeCount,
        isSaved: event.isSaved,
        saveCount: event.saveCount,
        commentCount: event.commentCount,
      );
      if (updated.isLiked != current.isLiked ||
          updated.likeCount != current.likeCount ||
          updated.isSaved != current.isSaved ||
          updated.saveCount != current.saveCount ||
          updated.commentCount != current.commentCount) {
        setState(() {
          _videos[index] = updated;
        });
      }
    }
  }

  void _onGlobalFollowChanged() {
    if (!mounted) return;
    final event = ProfileSyncService.instance.followEvents.value;
    if (event != null) {
      if (widget.feedType.toUpperCase() == 'FOLLOWING') {
        _fetchFeed(refresh: true);
        return;
      }
      setState(() {
        _videos = _videos.map((v) {
          if (v.creatorId == event.targetUserId) {
            return v.copyWith(isFollowing: event.isFollowing);
          }
          return v;
        }).toList();
      });
    }
  }

  void _onNewVideoUploaded() {
    final newVideo = VideoFeedManager.instance.latestUploadedVideoNotifier.value;
    if (newVideo == null || !mounted) return;

    if (!_videos.any((v) => v.id == newVideo.id)) {
      _clearPrefetchCache();
      setState(() {
        _videos.insert(0, newVideo);
        if (_isForYouFeed) {
          _forYouReplayPool.removeWhere((v) => v.id == newVideo.id);
          _forYouReplayPool.insert(0, newVideo);
        }
        _currentPage = 0;
        _savedPageIndices[widget.feedType] = 0;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
        _scheduleVideoPrefetch();
      });
    }
  }

  void _scheduleVideoPrefetch() {
    if (_prefetchScheduled) return;
    _prefetchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchScheduled = false;
      if (mounted) _prefetchUpcomingVideos();
    });
  }

  void _prefetchUpcomingVideos() {
    if (_videos.isEmpty || _currentPage >= _videos.length) return;

    final lastIndex = (_currentPage + _prefetchWindow).clamp(0, _videos.length - 1);
    for (var index = _currentPage + 1; index <= lastIndex; index++) {
      _prefetchVideo(_videos[index]);
    }
  }

  void _prefetchVideo(VideoModel video) {
    if (video.isImagePost ||
        video.videoUrl.trim().isEmpty ||
        _builtVideoIds.contains(video.id) ||
        _prefetchedControllers.containsKey(video.id) ||
        _prefetchingControllers.containsKey(video.id)) {
      return;
    }

    final generation = _prefetchGeneration;
    final future = _createPrefetchedController(video);
    _prefetchingControllers[video.id] = future;

    future.then((controller) {
      _prefetchingControllers.remove(video.id);
      if (controller == null) return;

      // A refresh can invalidate a warm-up while initialize() is still in
      // progress. Do not retain a controller for an obsolete feed snapshot.
      if (!mounted || generation != _prefetchGeneration || _builtVideoIds.contains(video.id)) {
        controller.dispose();
        return;
      }
      _prefetchedControllers[video.id] = controller;
    }).catchError((_) {
      _prefetchingControllers.remove(video.id);
    });
  }

  Future<VideoPlayerController?> _createPrefetchedController(VideoModel video) async {
    final rawUrl = video.videoUrl.trim();
    if (rawUrl.isEmpty) return null;

    VideoPlayerController createController({required bool useAsset}) {
      if (useAsset) return VideoPlayerController.asset(rawUrl);
      return VideoPlayerController.networkUrl(Uri.parse(VideoModel.toNetworkMediaUrl(rawUrl)));
    }

    final usesAsset = rawUrl.startsWith('assets/');
    var controller = createController(useAsset: usesAsset);
    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      await controller.dispose();
      if (!usesAsset) return null;

      // Match the post widget's existing asset-to-network fallback.
      controller = createController(useAsset: false);
      try {
        await controller.initialize();
        return controller;
      } catch (_) {
        await controller.dispose();
        return null;
      }
    }
  }

  void _clearPrefetchCache() {
    _prefetchGeneration++;
    for (final controller in _prefetchedControllers.values) {
      controller.dispose();
    }
    _prefetchedControllers.clear();
    // In-flight futures are allowed to finish and will dispose their
    // controllers when they observe the changed generation.
    _prefetchingControllers.clear();
  }

  VideoPlayerController? _takePrefetchedController(int videoId) {
    return _prefetchedControllers.remove(videoId);
  }

  void _addToForYouReplayPool(Iterable<VideoModel> videos) {
    if (!_isForYouFeed) return;
    for (final video in videos) {
      if (!_forYouReplayPool.any((existing) => existing.id == video.id)) {
        _forYouReplayPool.add(video);
      }
    }
  }

  void _recycleForYouFeed() {
    if (!_isForYouFeed ||
        _isRecyclingForYou ||
        _forYouReplayPool.isEmpty ||
        _videos.isEmpty) {
      return;
    }

    _isRecyclingForYou = true;
    final recycled = _dataSource.interleaveAndRandomizeVideos(
      List<VideoModel>.from(_forYouReplayPool),
      seed: DateTime.now().microsecondsSinceEpoch,
    );

    // Avoid showing the same item twice at the cycle boundary where
    // possible, while still keeping the rest of the cycle randomized.
    if (recycled.length > 1 && recycled.first.id == _videos.last.id) {
      final nextIndex = recycled.indexWhere((video) => video.id != _videos.last.id);
      if (nextIndex > 0) {
        final firstPart = recycled.sublist(0, nextIndex);
        recycled
          ..removeRange(0, nextIndex)
          ..addAll(firstPart);
      }
    }

    setState(() {
      _videos.addAll(recycled);
    });
    _isRecyclingForYou = false;
    _scheduleVideoPrefetch();
  }

  Future<void> _fetchFeed({bool refresh = false}) async {
    if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) return;

    if (refresh) {
      _apiPage = 0;
      _hasMore = true;
      _feedSeed = DateTime.now().millisecondsSinceEpoch;
    }

    if (_videos.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final fetched = await _dataSource.getFeed(
        page: _apiPage,
        size: 10,
        type: widget.feedType,
        seed: _feedSeed,
        forceRefresh: refresh,
      );

      if (!mounted) return;
      setState(() {
        if (refresh) {
          _videos = fetched;
          _forYouReplayPool.clear();
          _addToForYouReplayPool(fetched);
        } else {
          if (_apiPage == 0) {
            _videos = fetched;
          } else {
            _videos.addAll(fetched);
          }
          _addToForYouReplayPool(fetched);
        }
        _hasMore = fetched.length >= 10;
        _isLoading = false;
        _isLoadingMore = false;
      });

      _scheduleVideoPrefetch();

      if (widget.initialVideoId != null) {
        final targetIdx = _videos.indexWhere((v) => v.id == widget.initialVideoId);
        if (targetIdx != -1) {
          _currentPage = targetIdx;
          _savedPageIndices[widget.feedType] = targetIdx;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(targetIdx);
            }
          });
        } else {
          try {
            final directVideo = await _dataSource.getVideoById(widget.initialVideoId!);
            if (mounted) {
              setState(() {
                _videos.insert(0, directVideo);
                _currentPage = 0;
                _savedPageIndices[widget.feedType] = 0;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
            }
          } catch (_) {}
        }
      } else if (_currentPage >= _videos.length && _videos.isNotEmpty) {
        _currentPage = _videos.length - 1;
        _savedPageIndices[widget.feedType] = _currentPage;
      }

      if (_videos.isNotEmpty && widget.isActive && _currentPage < _videos.length) {
        _recordView(_videos[_currentPage].id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _apiPage++;
    await _fetchFeed(refresh: false);
  }

  void _recordView(int videoId) {
    _dataSource.incrementView(videoId);
  }

  void _onLikeToggled(int index) async {
    HapticFeedback.lightImpact();
    final video = _videos[index];
    final newLiked = !video.isLiked;
    final newLikeCount = newLiked ? video.likeCount + 1 : (video.likeCount > 0 ? video.likeCount - 1 : 0);

    final updated = video.copyWith(
      isLiked: newLiked,
      likeCount: newLikeCount,
    );

    setState(() {
      _videos[index] = updated;
    });

    ProfileSyncService.instance.notifyVideoInteraction(
      VideoInteractionEvent(
        videoId: video.id,
        isLiked: newLiked,
        likeCount: newLikeCount,
        video: updated,
      ),
    );

    try {
      final res = await _dataSource.toggleLike(video.id, currentlyLiked: video.isLiked);
      if (mounted && res['likeCount'] != null) {
        final serverLikeCount = res['likeCount'] as int;
        final serverLiked = res['isLiked'] as bool? ?? newLiked;
        if (serverLikeCount != _videos[index].likeCount || serverLiked != _videos[index].isLiked) {
          final confirmed = _videos[index].copyWith(
            isLiked: serverLiked,
            likeCount: serverLikeCount,
          );
          setState(() {
            _videos[index] = confirmed;
          });
          ProfileSyncService.instance.notifyVideoInteraction(
            VideoInteractionEvent(
              videoId: video.id,
              isLiked: serverLiked,
              likeCount: serverLikeCount,
              video: confirmed,
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _onSaveToggled(int index) async {
    HapticFeedback.lightImpact();
    final video = _videos[index];
    final newSaved = !video.isSaved;
    final newSaveCount = newSaved ? video.saveCount + 1 : (video.saveCount > 0 ? video.saveCount - 1 : 0);

    final updated = video.copyWith(
      isSaved: newSaved,
      saveCount: newSaveCount,
    );

    setState(() {
      _videos[index] = updated;
    });

    ProfileSyncService.instance.notifyVideoInteraction(
      VideoInteractionEvent(
        videoId: video.id,
        isSaved: newSaved,
        saveCount: newSaveCount,
        video: updated,
      ),
    );

    try {
      final res = await _dataSource.toggleSave(video.id, currentlySaved: video.isSaved);
      if (mounted && res['saveCount'] != null) {
        final serverSaveCount = res['saveCount'] as int;
        final serverSaved = res['isSaved'] as bool? ?? newSaved;
        if (serverSaveCount != _videos[index].saveCount || serverSaved != _videos[index].isSaved) {
          final confirmed = _videos[index].copyWith(
            isSaved: serverSaved,
            saveCount: serverSaveCount,
          );
          setState(() {
            _videos[index] = confirmed;
          });
          ProfileSyncService.instance.notifyVideoInteraction(
            VideoInteractionEvent(
              videoId: video.id,
              isSaved: serverSaved,
              saveCount: serverSaveCount,
              video: confirmed,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteVideoAt(int index) async {
    if (index < 0 || index >= _videos.length) return;
    final videoToDelete = _videos[index];

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Deleting video...', style: TextStyle(color: Colors.white)),
          ],
        ),
        duration: Duration(milliseconds: 1500),
        backgroundColor: Color(0xFF1E1E24),
      ),
    );

    final success = await _dataSource.deleteVideo(videoToDelete.id);
    if (!mounted) return;

    if (success) {
      ProfileSyncService.instance.notifyVideoDeleted(videoToDelete.id);
      setState(() {
        _videos.removeAt(index);
        if (_currentPage >= _videos.length && _videos.isNotEmpty) {
          _currentPage = _videos.length - 1;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video deleted successfully'),
          backgroundColor: Color(0xFF1E1E24),
        ),
      );

      if (_videos.isEmpty && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete video. Please check your connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  bool get _isStandalone => widget.hasBottomNav == false || widget.initialVideos != null;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (_videos.isEmpty) {
      final isFollowingTab = widget.feedType.toUpperCase() == 'FOLLOWING';
      return Scaffold(
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF202024),
          onRefresh: () => _fetchFeed(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFollowingTab ? Icons.person_add_alt_1_outlined : Icons.videocam_outlined,
                          color: Colors.white38,
                          size: 58,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isFollowingTab
                              ? 'No posts from people you follow yet. Follow creators to see their latest videos and photos here!'
                              : 'No videos available yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF202024),
            onRefresh: () => _fetchFeed(refresh: true),
            child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              key: PageStorageKey('video_page_view_${widget.feedType}'),
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _savedPageIndices[widget.feedType] = index;
                });

                if (index < _videos.length) {
                  _recordView(_videos[index].id);
                }

                if (index >= _videos.length - 2 && _hasMore) {
                  _loadMore();
                }
                if (index >= _videos.length - 2 && _isForYouFeed && !_hasMore) {
                  _recycleForYouFeed();
                }
                _scheduleVideoPrefetch();
              },
              itemBuilder: (context, index) {
                final video = _videos[index];
                _builtVideoIds.add(video.id);
                return _VideoPostWidget(
                  key: ValueKey('video_${video.id}_$index'),
                  video: video,
                  preloadedController: _takePrefetchedController(video.id),
                  isCurrentPage: _currentPage == index,
                  isActive: widget.isActive,
                  canDelete: widget.canDelete,
                  isStandalone: _isStandalone,
                  onLikeTap: () => _onLikeToggled(index),
                  onSaveTap: () => _onSaveToggled(index),
                  onDeleteVideo: () => _deleteVideoAt(index),
                  onCommentCountChanged: (newCount) {
                    final updated = _videos[index].copyWith(commentCount: newCount);
                    setState(() {
                      _videos[index] = updated;
                    });
                    ProfileSyncService.instance.notifyVideoInteraction(
                      VideoInteractionEvent(
                        videoId: updated.id,
                        commentCount: newCount,
                        video: updated,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ),
          if (widget.isStandalone || Navigator.of(context).canPop())
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoPostWidget extends StatefulWidget {
  final VideoModel video;
  final VideoPlayerController? preloadedController;
  final bool isCurrentPage;
  final bool isActive;
  final bool canDelete;
  final bool isStandalone;
  final VoidCallback onLikeTap;
  final VoidCallback onSaveTap;
  final VoidCallback? onDeleteVideo;
  final ValueChanged<int> onCommentCountChanged;

  const _VideoPostWidget({
    super.key,
    required this.video,
    this.preloadedController,
    required this.isCurrentPage,
    required this.isActive,
    this.canDelete = false,
    this.isStandalone = false,
    required this.onLikeTap,
    required this.onSaveTap,
    this.onDeleteVideo,
    required this.onCommentCountChanged,
  });

  @override
  State<_VideoPostWidget> createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<_VideoPostWidget>
    with RouteAware, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  VideoPlayerController? _audioController;
  PageController? _imageCarouselController;
  int _currentImageIndex = 0;
  bool _manuallyPaused = false;
  bool _hasControllerError = false;
  bool _showHeartAnimation = false;
  bool _isMuted = false;
  late bool _isFollowing;
  final List<TapGestureRecognizer> _hashtagRecognizers = [];

  @override
  bool get wantKeepAlive => true;

  bool get _hasCustomAudio {
    final audio = widget.video.resolvedAudioUrl;
    if (audio == null || audio.trim().isEmpty) return false;
    if (widget.video.isImagePost) return true;
    return audio != widget.video.resolvedVideoUrl;
  }

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.video.isFollowing;
    _imageCarouselController = PageController();
    WidgetsBinding.instance.addObserver(this);

    if (!widget.video.isImagePost) {
      _controller = widget.preloadedController;
      if (_controller != null) {
        _controller!.addListener(_videoListener);
        _finishControllerInitialization();
      } else {
        _initController();
      }
    }
    if (_hasCustomAudio) {
      if (widget.video.isImagePost) {
        _initAudioController();
      } else {
        // Stagger audio controller initialization on Android to prevent dual hardware decoder collisions
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _hasCustomAudio) {
            _initAudioController();
          }
        });
      }
    }
  }

  void _finishControllerInitialization() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    controller.setLooping(true);
    final vidVolume = _hasCustomAudio ? 0.0 : (_isMuted ? 0.0 : 1.0);
    controller.setVolume(vidVolume);
    if (mounted) {
      setState(() {
        _hasControllerError = false;
      });
    }
    if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
      controller.play();
    }
  }

  void _initController({bool isFallback = false}) {
    final rawUrl = widget.video.resolvedVideoUrl;
    if (rawUrl.isEmpty) {
      if (mounted) setState(() => _hasControllerError = true);
      return;
    }

    if (!isFallback && rawUrl.startsWith('assets/')) {
      _controller = VideoPlayerController.asset(
        rawUrl,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else {
      final networkUrl = VideoModel.toNetworkMediaUrl(rawUrl);
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(networkUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }

    _controller!.addListener(_videoListener);
    _controller!.initialize().then((_) async {
      if (!mounted) return;
      _finishControllerInitialization();
    }).catchError((error) {
      debugPrint('[_VideoPostWidget] Video init error for $rawUrl (isFallback: $isFallback): $error');
      if (!isFallback && rawUrl.startsWith('assets/')) {
        // Fallback to backend network stream if local APK asset bundle doesn't have the file
        if (mounted) {
          _controller?.removeListener(_videoListener);
          _controller?.dispose();
          _controller = null;
          _initController(isFallback: true);
        }
      } else {
        if (mounted) {
          setState(() {
            _hasControllerError = true;
          });
        }
      }
    });
  }

  void _initAudioController() {
    final audio = widget.video.resolvedAudioUrl;
    if (audio == null || audio.trim().isEmpty) return;

    if (_audioController != null) {
      _audioController!.removeListener(_audioListener);
      _audioController!.dispose();
      _audioController = null;
    }

    if (audio.startsWith('assets/')) {
      _audioController = VideoPlayerController.asset(
        audio,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else {
      _audioController = VideoPlayerController.networkUrl(
        Uri.parse(audio),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }

    _audioController!.addListener(_audioListener);
    _audioController!.initialize().then((_) async {
      if (!mounted) return;
      await _audioController!.setLooping(true);
      await _audioController!.setVolume(_isMuted ? 0.0 : 1.0);
      setState(() {});
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        await _audioController!.play();
      }
    }).catchError((error) {
      debugPrint('[VideoFeed] Audio controller init error: $error');
      // If custom audio fails on a video post, restore the main video audio so user still gets sound
      if (mounted && !widget.video.isImagePost && _controller != null && _controller!.value.isInitialized) {
        _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      }
    });
  }

  void _videoListener() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized) return;
    final value = _controller!.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      _controller!.seekTo(Duration.zero);
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        _controller!.play();
      }
    }
  }

  void _audioListener() {
    if (!mounted || _audioController == null || !_audioController!.value.isInitialized) return;
    final value = _audioController!.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      _audioController!.seekTo(Duration.zero);
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        _audioController!.play();
      }
    }
  }

  void _handleDoubleTap() {
    setState(() {
      _showHeartAnimation = true;
    });
    if (!widget.video.isLiked) {
      widget.onLikeTap();
    }
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  Widget _buildImagePost(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildMediaError(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
          ),
        );
      },
      errorBuilder: (_, _, _) => _buildMediaError(),
    );
  }

  Widget _buildMediaError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 54),
        const SizedBox(height: 10),
        Text(
          'Photo unavailable',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null) {
        routeObserver.subscribe(this, modalRoute);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _VideoPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.isFollowing != widget.video.isFollowing) {
      _isFollowing = widget.video.isFollowing;
    }

    if (widget.video.isImagePost) {
      if (_controller != null) {
        _controller!.pause();
        _controller!.removeListener(_videoListener);
        _controller!.dispose();
        _controller = null;
      }
      if (oldWidget.video.id != widget.video.id) {
        _currentImageIndex = 0;
        if (_imageCarouselController != null && _imageCarouselController!.hasClients) {
          _imageCarouselController!.jumpToPage(0);
        }
      }
    } else {
      if (_controller == null || oldWidget.video.resolvedVideoUrl != widget.video.resolvedVideoUrl) {
        if (_controller != null) {
          _controller!.removeListener(_videoListener);
          _controller!.dispose();
          _controller = null;
        }
        _initController();
      }
    }

    if (oldWidget.video.resolvedAudioUrl != widget.video.resolvedAudioUrl) {
      if (_audioController != null) {
        _audioController!.removeListener(_audioListener);
        _audioController!.dispose();
        _audioController = null;
      }
      if (_hasCustomAudio) {
        _initAudioController();
      }
    }

    final shouldPlay = widget.isActive && widget.isCurrentPage && !_manuallyPaused;
    if (_controller != null && _controller!.value.isInitialized) {
      if (shouldPlay && !_controller!.value.isPlaying) {
        _controller!.play();
      } else if (!shouldPlay && _controller!.value.isPlaying) {
        _controller!.pause();
      }
    } else if (shouldPlay && _hasControllerError) {
      _hasControllerError = false;
      _initController(isFallback: true);
    }
    if (_audioController != null && _audioController!.value.isInitialized) {
      if (shouldPlay && !_audioController!.value.isPlaying) {
        _audioController!.play();
      } else if (!shouldPlay && _audioController!.value.isPlaying) {
        _audioController!.pause();
      }
    }
  }

  @override
  void didPushNext() {
    if (_controller != null && _controller!.value.isInitialized && _controller!.value.isPlaying) {
      _controller!.pause();
    }
    if (_audioController != null && _audioController!.value.isInitialized && _audioController!.value.isPlaying) {
      _audioController!.pause();
    }
    if (mounted) setState(() {});
  }

  @override
  void didPopNext() {
    final shouldPlay = widget.isActive && widget.isCurrentPage && !_manuallyPaused;
    if (shouldPlay) {
      if (_controller != null && _controller!.value.isInitialized) {
        _controller!.play();
      }
      if (_audioController != null && _audioController!.value.isInitialized) {
        _audioController!.play();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_controller != null && _controller!.value.isInitialized && _controller!.value.isPlaying) {
        _controller!.pause();
      }
      if (_audioController != null && _audioController!.value.isInitialized && _audioController!.value.isPlaying) {
        _audioController!.pause();
      }
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      final shouldPlay = widget.isActive && widget.isCurrentPage && !_manuallyPaused;
      if (shouldPlay) {
        if (_controller != null && _controller!.value.isInitialized) {
          _controller!.play();
        }
        if (_audioController != null && _audioController!.value.isInitialized) {
          _audioController!.play();
        }
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    for (final recognizer in _hashtagRecognizers) {
      recognizer.dispose();
    }
    _hashtagRecognizers.clear();
    _imageCarouselController?.dispose();
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
      _controller = null;
    }
    if (_audioController != null) {
      _audioController!.removeListener(_audioListener);
      _audioController!.dispose();
      _audioController = null;
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_hasControllerError && !widget.video.isImagePost) {
      setState(() => _hasControllerError = false);
      _initController(isFallback: true);
      return;
    }
    if (_controller == null && _audioController == null) return;
    setState(() {
      final isCurrentlyPlaying = (_controller != null && _controller!.value.isPlaying) ||
          (_audioController != null && _audioController!.value.isPlaying);

      if (isCurrentlyPlaying) {
        _manuallyPaused = true;
        _controller?.pause();
        _audioController?.pause();
      } else {
        _manuallyPaused = false;
        final vidVolume = _hasCustomAudio ? 0.0 : (_isMuted ? 0.0 : 1.0);
        _controller?.setVolume(vidVolume);
        _controller?.play();
        _audioController?.setVolume(_isMuted ? 0.0 : 1.0);
        _audioController?.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      final vidVolume = _hasCustomAudio ? 0.0 : (_isMuted ? 0.0 : 1.0);
      _controller?.setVolume(vidVolume);
      _audioController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _confirmDeleteVideo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete this video? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      widget.onDeleteVideo?.call();
    }
  }

  void _openHashtagSearch(String hashtag) {
    final match = RegExp(r'^#[a-zA-Z0-9_]+').firstMatch(hashtag);
    if (match == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialQuery: match.group(0)),
      ),
    );
  }

  Widget _buildCaptionWithHashtags(VideoModel video) {
    for (final recognizer in _hashtagRecognizers) {
      recognizer.dispose();
    }
    _hashtagRecognizers.clear();

    String text = video.caption.trim();

    // If tags exist and aren't already part of caption, append them so they display on posted video
    if (video.tags.isNotEmpty) {
      final missingTags = video.tags.where((t) {
        final clean = t.replaceAll('#', '').trim().toLowerCase();
        return clean.isNotEmpty && !text.toLowerCase().contains('#$clean');
      }).toList();
      if (missingTags.isNotEmpty) {
        final appendedTags = missingTags.map((t) {
          final clean = t.replaceAll('#', '').trim();
          return '#$clean';
        }).join(' ');
        text = text.isEmpty ? appendedTags : '$text $appendedTags';
      }
    }

    if (text.isEmpty) return const SizedBox.shrink();

    // Parse text into spans (words starting with # are cyan, @ are light blue)
    final words = text.split(RegExp(r'(\s+)'));
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;
      final isLast = i == words.length - 1;
      final trailing = isLast ? '' : ' ';

      if (word.startsWith('#')) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _openHashtagSearch(word);
        _hashtagRecognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: '$word$trailing',
            recognizer: recognizer,
            style: const TextStyle(
              color: Color(0xFF20D5EC), // Vibrant cyan for hashtags
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      } else if (word.startsWith('@')) {
        spans.add(
          TextSpan(
            text: '$word$trailing',
            style: const TextStyle(
              color: Color(0xFF60A5FA), // Light blue for user mentions
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$word$trailing',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicProfileScreen(
          userId: widget.video.creatorId > 0 ? widget.video.creatorId : null,
          username: widget.video.username,
          displayName: widget.video.displayName,
          avatarUrl: widget.video.avatarUrl,
          isFollowing: _isFollowing,
          initialVideos: [widget.video],
        ),
      ),
    );
  }

  void _toggleFollow() async {
    final newFollowState = !_isFollowing;
    setState(() {
      _isFollowing = newFollowState;
    });

    ProfileSyncService.instance.notifyFollowChanged(
      targetUserId: widget.video.creatorId,
      isFollowing: newFollowState,
      targetUser: UserModel(
        id: widget.video.creatorId,
        username: widget.video.username.replaceAll('@', ''),
        email: '',
        displayName: widget.video.displayName,
        avatarUrl: widget.video.avatarUrl ?? '',
        isVerified: widget.video.isVerified,
        isFollowing: newFollowState,
        followersCount: 0,
        followingCount: 0,
      ),
    );

    final identifier = widget.video.creatorId > 0 ? widget.video.creatorId : widget.video.username;
    await FeedRemoteDataSource.instance.toggleFollow(identifier, skipNotify: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final video = widget.video;
    final avatar = (video.avatarUrl != null && video.avatarUrl!.isNotEmpty)
        ? video.avatarUrl!
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';

    final mediaPadding = MediaQuery.of(context).padding;
    final double infoBottom = widget.isStandalone
        ? (mediaPadding.bottom + 20.0)
        : (mediaPadding.bottom + 80.0);
    final double actionButtonsBottom = widget.isStandalone
        ? (mediaPadding.bottom + 24.0)
        : (mediaPadding.bottom + 84.0);
    final double dotsBottom = widget.isStandalone
        ? (mediaPadding.bottom + 175.0)
        : (mediaPadding.bottom + 235.0);
    final double gradientHeight = widget.isStandalone ? 280.0 : 340.0;

    return Stack(
      children: [
        // Hidden video player surface required by Android ExoPlayer to output audio
        if (_audioController != null && _audioController!.value.isInitialized)
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: VideoPlayer(_audioController!),
            ),
          ),

        // Background Video or Photo
        Positioned.fill(
          child: Container(
            color: const Color(0xFF121216),
            child: widget.video.isImagePost
                ? GestureDetector(
                    onTap: _hasCustomAudio ? _togglePlayPause : null,
                    onDoubleTap: _handleDoubleTap,
                    behavior: HitTestBehavior.opaque,
                    child: widget.video.isMultiImagePost
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              PageView.builder(
                                controller: _imageCarouselController,
                                physics: const BouncingScrollPhysics(),
                                itemCount: widget.video.resolvedMediaUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return Center(
                                    child: _buildImagePost(widget.video.resolvedMediaUrls[index]),
                                  );
                                },
                              ),
                              // Round dots pagination indicator
                              Positioned(
                                bottom: dotsBottom,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        widget.video.resolvedMediaUrls.length,
                                        (index) {
                                          final isSelected = index == _currentImageIndex;
                                          return GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              _imageCarouselController?.animateToPage(
                                                index,
                                                duration: const Duration(milliseconds: 250),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: isSelected ? 8 : 6,
                                                height: isSelected ? 8 : 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white.withValues(alpha: 0.35),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: _buildImagePost(
                              video.resolvedMediaUrls.isNotEmpty
                                  ? video.resolvedMediaUrls.first
                                  : VideoModel.resolveMediaUrl(video.videoUrl),
                            ),
                          ),
                  )
                : (_controller != null &&
                        _controller!.value.isInitialized &&
                        _controller!.value.size.width > 0 &&
                        _controller!.value.size.height > 0)
                    ? GestureDetector(
                        onTap: _togglePlayPause,
                        onDoubleTap: _handleDoubleTap,
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller!.value.size.width,
                                  height: _controller!.value.size.height,
                                  child: VideoPlayer(_controller!),
                                ),
                              ),
                            ),
                            // Center Pause / Play indicator icon when paused
                            if (!_controller!.value.isPlaying)
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                          ],
                        ),
                      )
                    : Center(
                        child: (_controller != null && (_controller!.value.hasError || _hasControllerError))
                            ? GestureDetector(
                                onTap: () {
                                  setState(() => _hasControllerError = false);
                                  _initController(isFallback: true);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_circle_outline_rounded, color: Colors.white24, size: 54),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Video playback paused (Tap to play)',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              ),
                      ),
          ),
        ),

        // Animated Double-Tap Heart pop
        if (_showHeartAnimation)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1.2),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 96,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // Carousel page indicator badge (Top Right)
        if (widget.video.isMultiImagePost)
          Positioned(
            top: widget.isStandalone
                ? (MediaQuery.of(context).padding.top + 16)
                : (MediaQuery.of(context).padding.top + 64),
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${widget.video.resolvedMediaUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Volume / Mute toggle button (Top Right)
        if (!widget.video.isImagePost)
          Positioned(
            top: widget.isStandalone
                ? (MediaQuery.of(context).padding.top + 16)
                : (MediaQuery.of(context).padding.top + 64),
            right: 8,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

        // Dark gradient overlay at the bottom for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: gradientHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Right side interaction buttons
        Positioned(
          right: 8,
          bottom: actionButtonsBottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Avatar with + button
              SizedBox(
                height: 56,
                width: 48,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _goToProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.2),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(avatar),
                          onBackgroundImageError: (_, _) {},
                          backgroundColor: Colors.grey[900],
                        ),
                      ),
                    ),
                    // Only show + badge if NOT already followed and NOT current user
                    if (!_isFollowing && !widget.video.isMe)
                      Positioned(
                        bottom: 0,
                        child: _AnimatedFollowButton(
                          onFollow: _toggleFollow,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Like
              _InteractionButton(
                icon: Icons.favorite,
                label: video.formattedLikes,
                isActive: video.isLiked,
                activeColor: Colors.red,
                onTap: widget.onLikeTap,
                onLongPress: () => VideoLikesBottomSheet.show(
                  context,
                  videoId: video.id,
                  initialLikeCount: video.likeCount,
                  initialCommentCount: video.commentCount,
                  initialTab: 1,
                ),
                onLabelTap: () => VideoLikesBottomSheet.show(
                  context,
                  videoId: video.id,
                  initialLikeCount: video.likeCount,
                  initialCommentCount: video.commentCount,
                  initialTab: 1,
                ),
              ),

              // Comment
              _InteractionButton(
                icon: Icons.comment,
                label: video.formattedComments,
                onTap: () {
                  VideoLikesBottomSheet.show(
                    context,
                    videoId: video.id,
                    initialCommentCount: video.commentCount,
                    initialLikeCount: video.likeCount,
                    initialTab: 0,
                    videoCreatorId: video.creatorId,
                    videoCreatorUsername: video.username,
                    onCommentCountChanged: widget.onCommentCountChanged,
                  );
                },
              ),

              // Bookmark / Save
              _InteractionButton(
                icon: Icons.bookmark,
                label: video.formattedSaves,
                isActive: video.isSaved,
                activeColor: Colors.amber,
                onTap: widget.onSaveTap,
              ),

              // Share
              _InteractionButton(
                icon: Icons.reply,
                label: 'Share',
                showLabel: false,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ShareBottomSheet(),
                  );
                },
              ),

              // Record/Music Disc
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SoundDetailPage(
                        soundId: video.soundId?.toString() ?? video.id.toString(),
                        title: video.musicTitle.isNotEmpty ? video.musicTitle : 'Original Sound',
                        artist: (video.musicArtist != null && video.musicArtist!.isNotEmpty)
                            ? video.musicArtist!
                            : (video.displayName.isNotEmpty ? video.displayName : video.username),
                        albumArtUrl: video.thumbnailUrl,
                        audioUrl: video.audioUrl,
                        creatorId: video.creatorId,
                        creatorUsername: (video.musicArtist != null && video.musicArtist!.isNotEmpty)
                            ? video.musicArtist!.replaceAll('@', '').trim()
                            : video.username.replaceAll('@', '').trim(),
                        sourceVideo: video,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.black,
                    backgroundImage: NetworkImage(
                      (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
                          ? video.thumbnailUrl!
                          : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=100',
                    ),
                    onBackgroundImageError: (_, _) {},
                  ),
                ),
              ),

              // Delete button (visible ONLY when viewing posted videos from profile and owned by current user)
              if (widget.canDelete && widget.video.isOwner) ...[
                const SizedBox(height: 16),
                _InteractionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  activeColor: const Color(0xFFFE2C55),
                  onTap: _confirmDeleteVideo,
                ),
              ],
            ],
          ),
        ),

        // Bottom left user info and caption
        Positioned(
          left: 16,
          bottom: infoBottom,
          right: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _goToProfile,
                    child: Text(
                      video.username.startsWith('@') ? video.username : '@${video.username}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (widget.video.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _buildCaptionWithHashtags(video),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SoundDetailPage(
                        soundId: video.soundId?.toString() ?? video.id.toString(),
                        title: video.musicTitle,
                        artist: (video.musicArtist != null && video.musicArtist!.isNotEmpty)
                            ? video.musicArtist!
                            : (video.displayName.isNotEmpty ? video.displayName : video.username),
                        albumArtUrl: video.thumbnailUrl,
                        audioUrl: video.audioUrl,
                        creatorId: video.creatorId,
                        creatorUsername: (video.musicArtist != null && video.musicArtist!.isNotEmpty)
                            ? video.musicArtist!.replaceAll('@', '').trim()
                            : video.username.replaceAll('@', '').trim(),
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.video.musicTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showLabel;
  final Color? activeColor;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLabelTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    this.showLabel = true,
    this.activeColor,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
    this.onLabelTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isActive && activeColor != null) ? activeColor! : Colors.white;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onLabelTap ?? onTap,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

/// Dynamic Animated Follow Button with pop bounce, rotation, checkmark morph,
/// glowing ripple shockwave ring, and smooth exit fade
class _AnimatedFollowButton extends StatefulWidget {
  final VoidCallback onFollow;

  const _AnimatedFollowButton({required this.onFollow});

  @override
  State<_AnimatedFollowButton> createState() => _AnimatedFollowButtonState();
}

class _AnimatedFollowButtonState extends State<_AnimatedFollowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _checkMorphAnimation;
  late Animation<double> _rippleScaleAnimation;
  late Animation<double> _rippleOpacityAnimation;
  late Animation<double> _exitScaleAnimation;
  late Animation<double> _exitOpacityAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Initial pop bounce (0.0 to 0.45)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.42).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.42, end: 1.15).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.15),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65),
    ));

    // Rotation (0.0 to 0.40)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
      ),
    );

    // Morph to checkmark (0.15 to 0.45)
    _checkMorphAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.45, curve: Curves.easeInOut),
    );

    // Color transition from TikTok red to emerald green (0.10 to 0.40)
    _colorAnimation = ColorTween(
      begin: const Color(0xFFFE2C55),
      end: const Color(0xFF10B981),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.40, curve: Curves.easeInOut),
    ));

    // Ripple shockwave ring
    _rippleScaleAnimation = Tween<double>(begin: 0.9, end: 2.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _rippleOpacityAnimation = Tween<double>(begin: 0.9, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.50, curve: Curves.easeOut),
      ),
    );

    // Final shrink & exit (0.68 to 1.0)
    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 1.0, curve: Curves.easeInBack),
      ),
    );
    _exitOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerFollow() {
    if (_isAnimating) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnimating = true;
    });

    _controller.forward().then((_) {
      if (mounted) {
        widget.onFollow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerFollow,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _scaleAnimation.value * _exitScaleAnimation.value;
          final opacity = _exitOpacityAnimation.value.clamp(0.0, 1.0);
          final showCheck = _checkMorphAnimation.value >= 0.5;

          return Opacity(
            opacity: opacity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Glowing expanding ripple ring
                if (_isAnimating && _rippleOpacityAnimation.value > 0.01)
                  Transform.scale(
                    scale: _rippleScaleAnimation.value,
                    child: Opacity(
                      opacity: _rippleOpacityAnimation.value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFE2C55),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Button pill
                Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: _colorAnimation.value ?? const Color(0xFFFE2C55),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_colorAnimation.value ?? const Color(0xFFFE2C55)).withValues(alpha: 0.55),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: Icon(
                        showCheck ? Icons.check_rounded : Icons.add,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
