import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../network/api_client.dart';

/// Displays the first frame of a video as a thumbnail without starting playback.
class VideoThumbnail extends StatefulWidget {
  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final String videoUrl;
  final String? fallbackUrl;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    final rawUrl = widget.videoUrl.trim();
    if (rawUrl.isEmpty) return;

    VideoPlayerController? controller;
    try {
      if (rawUrl.startsWith('assets/')) {
        controller = VideoPlayerController.asset(rawUrl);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(_resolveNetworkUrl(rawUrl)));
      }
      await controller.initialize();
      await controller.seekTo(Duration.zero);
      await controller.pause();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller?.dispose();
    }
  }

  String _resolveNetworkUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final host = ApiClient.baseUrl.replaceAll('/api/v1', '');
    if (url.startsWith('/')) return '$host$url';
    return '$host/$url';
  }

  Widget _fallback() {
    final fallback = widget.fallbackUrl?.trim() ?? '';
    if (fallback.startsWith('assets/')) {
      return Image.asset(
        fallback,
        fit: widget.fit,
        errorBuilder: (_, _, _) => widget.placeholder ?? const SizedBox.expand(),
      );
    }
    if (fallback.startsWith('http://') || fallback.startsWith('https://')) {
      return Image.network(
        fallback,
        fit: widget.fit,
        errorBuilder: (_, _, _) => widget.placeholder ?? const SizedBox.expand(),
      );
    }
    return widget.placeholder ?? const SizedBox.expand();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return _fallback();

    final size = controller.value.size;
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
