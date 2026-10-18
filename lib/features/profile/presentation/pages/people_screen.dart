import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../search_discover/presentation/pages/search_screen.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../../data/datasources/static_people_data.dart';
import '../../domain/entities/person_suggestion.dart';
import '../widgets/person_card.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<PersonSuggestion> _peopleList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPeopleList();
    ProfileSyncService.instance.followEvents.addListener(_onGlobalFollowEvent);
  }

  @override
  void dispose() {
    ProfileSyncService.instance.followEvents.removeListener(_onGlobalFollowEvent);
    super.dispose();
  }

  void _onGlobalFollowEvent() {
    final event = ProfileSyncService.instance.followEvents.value;
    if (event != null && mounted) {
      final targetStr = event.targetUserId.toString();
      final idx = _peopleList.indexWhere((p) => p.id == targetStr);
      if (idx != -1 && _peopleList[idx].isFollowed != event.isFollowing) {
        setState(() {
          _peopleList[idx] = _peopleList[idx].copyWith(isFollowed: event.isFollowing);
        });
      }
    }
  }

  Future<void> _fetchPeopleList() async {
    try {
      final suggestions = await ProfileRemoteDataSource.instance.getSuggestedUsers();
      if (mounted) {
        if (suggestions.isNotEmpty) {
          setState(() {
            _peopleList = suggestions.map((u) {
              final displayName = u.displayName.trim().isNotEmpty ? u.displayName.trim() : u.username;
              final subtitle = (u.bio != null && u.bio!.trim().isNotEmpty)
                  ? u.bio!.trim()
                  : (u.followsYou ? 'Follows you' : 'Suggested creator');
              final avatar = (u.avatarUrl != null && u.avatarUrl!.trim().isNotEmpty)
                  ? u.avatarUrl!.trim()
                  : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80';

              return PersonSuggestion(
                id: u.id.toString(),
                username: u.username,
                name: displayName,
                subtitle: subtitle,
                avatarUrl: avatar,
                followsYou: u.followsYou,
                isFollowed: u.isFollowing,
              );
            }).toList();
            _isLoading = false;
          });
        } else {
          // If empty list returned from DB, use static fallback
          setState(() {
            _peopleList = List.from(StaticPeopleData.suggestions);
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        // Fallback to static data on network error
        if (_peopleList.isEmpty) {
          setState(() {
            _peopleList = List.from(StaticPeopleData.suggestions);
            _isLoading = false;
          });
        }
      }
    }
  }

  void _removePerson(int index) {
    setState(() {
      _peopleList.removeAt(index);
    });
  }

  void _toggleFollow(int index) async {
    final person = _peopleList[index];
    final newStatus = !person.isFollowed;
    final targetId = int.tryParse(person.id);

    // 1. Optimistic update
    setState(() {
      _peopleList[index] = person.copyWith(isFollowed: newStatus);
    });

    // 2. Perform network call if real DB user
    if (targetId != null && targetId > 0) {
      try {
        if (newStatus) {
          await ProfileRemoteDataSource.instance.toggleFollow(targetId);
        } else {
          await ProfileRemoteDataSource.instance.unfollow(targetId);
        }
      } catch (_) {
        // Revert on error
        if (mounted) {
          setState(() {
            _peopleList[index] = person.copyWith(isFollowed: !newStatus);
          });
        }
        return;
      }
    }

    // 3. Broadcast follow event to keep profile count in exact sync
    ProfileSyncService.instance.notifyFollowChanged(
      targetUserId: targetId ?? (index + 1),
      isFollowing: newStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: AppColors.voidBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () {
            // Do not redirect anywhere
          },
        ),
        title: const Text(
          'Friends',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPeopleList,
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E24),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            // Headline & Subtitle
            const Text(
              'People You May Know',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect with friends and creators.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 20),

            // Stacked Cards List
            if (_isLoading && _peopleList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else if (_peopleList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                alignment: Alignment.center,
                child: const Text(
                  'No more suggestions right now',
                  style: TextStyle(color: AppColors.outline, fontSize: 14),
                ),
              )
            else
              ...List.generate(_peopleList.length, (index) {
                final person = _peopleList[index];
                return PersonCard(
                  key: ValueKey(person.id),
                  person: person,
                  onRemove: () => _removePerson(index),
                  onFollowToggle: () => _toggleFollow(index),
                );
              }),
          ],
        ),
      ),
    );
  }
}
