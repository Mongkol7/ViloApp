import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/media_url.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/presentation/pages/sound_detail_page.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../mock/profile_mock_data.dart';
import '../style/pulse_tokens.dart';

/// A single track row in the Sounds tab. Owns just its own expand/collapse
/// state for "N similar sounds" — no scroll behavior, it's a plain item
/// placed inside a SliverList by the parent.
class SoundListItem extends StatefulWidget {
  const SoundListItem({
    super.key,
    required this.sound,
    this.isCreator = false,
    this.onSoundUpdated,
    this.onSoundDeleted,
  });

  final SoundTrack sound;
  final bool isCreator;
  final ValueChanged<SoundTrack>? onSoundUpdated;
  final ValueChanged<SoundTrack>? onSoundDeleted;

  @override
  State<SoundListItem> createState() => _SoundListItemState();
}

class _SoundListItemState extends State<SoundListItem> {
  bool _expanded = false;
  late String _currentCoverUrl;
  bool _isUpdatingCover = false;
  bool _isDeleting = false;

  bool get _isOwner {
    if (!widget.isCreator) return false;
    final username = widget.sound.creatorUsername ?? widget.sound.artist;
    final id = widget.sound.creatorId?.toString();
    return ProfileSyncService.instance.isCurrentUser(
      username: username,
      id: id,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentCoverUrl = widget.sound.coverUrl;
  }

  @override
  void didUpdateWidget(covariant SoundListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sound.coverUrl != widget.sound.coverUrl) {
      _currentCoverUrl = widget.sound.coverUrl;
    }
  }

  Future<void> _pickAndEditCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      setState(() => _isUpdatingCover = true);

      final soundId = widget.sound.id;
      if (soundId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot edit cover for this sound')),
          );
        }
        return;
      }

      final updated = await FeedRemoteDataSource.instance.updateSoundCover(
        soundId: soundId,
        coverPath: picked.path,
        coverBytes: picked.bytes,
        coverFilename: picked.name,
      );

      if (mounted) {
        if (updated != null) {
          setState(() {
            _currentCoverUrl = updated.coverUrl;
          });
          widget.onSoundUpdated?.call(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cover art updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update cover art. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating cover: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingCover = false);
      }
    }
  }

  Future<void> _confirmDeleteSound() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Sound', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${widget.sound.title}"? Existing videos using this sound will remain intact.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_sound_dialog_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final soundId = widget.sound.id;
    if (soundId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete this sound: invalid ID')),
      );
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final success = await FeedRemoteDataSource.instance.deleteSound(soundId.toString());
      if (mounted) {
        if (success) {
          widget.onSoundDeleted?.call(widget.sound);
          ProfileSyncService.instance.notifySoundDeleted(soundId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF1E1E24),
              content: Text('Sound deleted successfully!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF2C1A1D),
              content: Text('Failed to delete sound. You may not have permission.', style: TextStyle(color: Colors.redAccent)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C1A1D),
            content: Text('Error deleting sound: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sound = widget.sound;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SoundDetailPage(
              soundId: sound.id?.toString(),
              title: sound.title,
              artist: sound.artist,
              albumArtUrl: _currentCoverUrl,
              audioUrl: sound.audioUrl,
              videosCount: sound.usedByLabel,
              creatorId: sound.creatorId,
              creatorUsername: sound.creatorUsername,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: PulseSpacing.stackGap),
        padding: const EdgeInsets.all(PulseSpacing.containerPadding),
        decoration: BoxDecoration(
          color: PulseColors.surface,
          borderRadius: BorderRadius.circular(PulseRadius.cardRadius),
          border: Border.all(color: PulseColors.surfaceStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(PulseRadius.sm),
                      child: Image.network(
                        resolveBackendMediaUrl(_currentCoverUrl),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: PulseColors.surfaceContainer,
                          child: const Icon(Icons.music_note, color: Colors.white24, size: 24),
                        ),
                      ),
                    ),
                    if (_isOwner)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: GestureDetector(
                          onTap: _isUpdatingCover ? null : _pickAndEditCover,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: PulseSpacing.inlineGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound.title,
                        style: PulseTypography.bodyLg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Used by ${sound.usedByLabel} videos',
                        style: PulseTypography.bodyMd,
                      ),
                      if (_isOwner) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: _isUpdatingCover ? null : _pickAndEditCover,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: PulseColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isUpdatingCover)
                                      const SizedBox(
                                        width: 11,
                                        height: 11,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.image_outlined, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Edit Cover',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              key: const Key('delete_sound_button'),
                              onTap: _isDeleting ? null : _confirmDeleteSound,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A1C20),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isDeleting)
                                      const SizedBox(
                                        width: 11,
                                        height: 11,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.redAccent,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.delete_outline_rounded, size: 12, color: Colors.redAccent),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.play_circle_outline,
                    color: PulseColors.onSurface,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SoundDetailPage(
                          soundId: sound.id?.toString(),
                          title: sound.title,
                          artist: sound.artist,
                          albumArtUrl: _currentCoverUrl,
                          audioUrl: sound.audioUrl,
                          videosCount: sound.usedByLabel,
                          creatorId: sound.creatorId,
                          creatorUsername: sound.creatorUsername,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bookmark_border_rounded,
                    color: PulseColors.onSurface,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            if (sound.similarCount > 0)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: PulseSpacing.inlineGap),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${sound.similarCount} similar sounds',
                        style: PulseTypography.bodyMd,
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: PulseColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(top: PulseSpacing.inlineGap),
                child: Text(
                  'Similar sound previews go here (static placeholder).',
                  style: PulseTypography.bodyMd,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
