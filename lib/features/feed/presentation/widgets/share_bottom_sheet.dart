import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/video_model.dart';
import '../../../inbox_activity/data/datasources/inbox_message_manager.dart';
import '../../../inbox_activity/domain/entities/inbox_item.dart';
import '../../../search_discover/data/datasources/search_remote_data_source.dart';
import '../../../search_discover/domain/entities/search_results.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../auth/data/datasources/token_storage.dart';

class ShareBottomSheet extends StatefulWidget {
  final VideoModel video;

  const ShareBottomSheet({super.key, required this.video});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchAccount> _searchResults = [];
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DirectMessageThread> get _threads => InboxMessageManager.instance.threads;

  Future<void> _searchUsers(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final result = await SearchRemoteDataSource.instance.search(query, type: 'USERS');
      if (!mounted) return;
      setState(() {
        _searchResults = (result['accounts'] as List?)?.whereType<SearchAccount>().toList() ?? [];
      });
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _shareToThread(DirectMessageThread thread) async {
    await _shareToUser(
      username: thread.username,
      displayName: thread.username,
      avatarUrl: thread.avatarUrl,
      threadId: thread.id,
    );
  }

  Future<void> _shareToAccount(SearchAccount account) async {
    final cleanUsername = account.username.replaceAll('@', '').trim();
    if (cleanUsername.isEmpty) return;
    await _shareToUser(
      username: cleanUsername,
      displayName: account.displayName,
      avatarUrl: account.avatarUrl,
      threadId: InboxMessageManager.buildThreadId(_myHandle(), cleanUsername),
    );
  }

  String _myHandle() {
    final profile = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    return profile?.username ?? ProfileSyncService.instance.currentUsername;
  }

  Future<void> _shareToUser({
    required String username,
    required String displayName,
    required String avatarUrl,
    required String threadId,
  }) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: 'Shared a video',
      isMe: true,
      senderHandle: _myHandle(),
      timestamp: 'Just now',
      contentType: 'VIDEO',
      sharedVideoId: widget.video.id > 0 ? widget.video.id : null,
      sharedVideoUrl: widget.video.resolvedVideoUrl,
      sharedVideoThumbnailUrl: widget.video.thumbnailUrl,
      sharedVideoCreator: widget.video.username,
      sharedVideoCaption: widget.video.caption,
    );
    try {
      final manager = InboxMessageManager.instance;
      manager.addOrUpdateThread(DirectMessageThread(
        id: threadId,
        username: username,
        avatarUrl: avatarUrl,
        lastMessage: message.text,
        timeAgo: 'Just now',
        isVerified: false,
        recipientHandle: username,
        messages: const [],
      ));
      await manager.addMessageToThread(threadId, message);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video shared with @$displayName')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share video: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Share video', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            TextField(
              controller: _searchController,
              onSubmitted: _searchUsers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search people',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: IconButton(
                  onPressed: () => _searchUsers(_searchController.text),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white70),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            if (_isSearching)
              const Center(child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Colors.white)))
            else if (_searchResults.isNotEmpty)
              SizedBox(
                height: 78,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchResults.length,
                  itemBuilder: (_, index) {
                    final account = _searchResults[index];
                    return _RecipientAvatar(
                      label: account.username,
                      avatarUrl: account.avatarUrl,
                      onTap: () => _shareToAccount(account),
                    );
                  },
                ),
              )
            else if (_threads.isNotEmpty)
              SizedBox(
                height: 78,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _threads.length,
                  itemBuilder: (_, index) {
                    final thread = _threads[index];
                    return _RecipientAvatar(
                      label: thread.username,
                      avatarUrl: thread.avatarUrl,
                      onTap: () => _shareToThread(thread),
                    );
                  },
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Search for a user to share this video.', style: TextStyle(color: Colors.white60)),
              ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF2F80ED), child: Icon(Icons.link, color: Colors.white)),
              title: const Text('Copy video link', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: widget.video.resolvedVideoUrl));
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientAvatar extends StatelessWidget {
  final String label;
  final String avatarUrl;
  final VoidCallback onTap;

  const _RecipientAvatar({required this.label, required this.avatarUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.startsWith('http') ? null : const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
