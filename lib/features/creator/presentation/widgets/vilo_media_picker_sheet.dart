import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';

class ViloMediaPickerBottomSheet extends StatefulWidget {
  const ViloMediaPickerBottomSheet({super.key});

  @override
  State<ViloMediaPickerBottomSheet> createState() =>
      _ViloMediaPickerBottomSheetState();
}

class _ViloMediaPickerBottomSheetState
    extends State<ViloMediaPickerBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _selectedIndices = {};
  bool _multiSelectEnabled = true;

  final List<Map<String, dynamic>> _mockMediaItems = [
    {
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
      'isVideo': true,
      'duration': '0:15',
    },
    {
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
      'isVideo': false,
      'duration': null,
    },
    {
      'url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
      'isVideo': true,
      'duration': '0:42',
    },
    {
      'url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop&q=80',
      'isVideo': false,
      'duration': null,
    },
    {
      'url': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80',
      'isVideo': true,
      'duration': '1:02',
    },
    {
      'url': 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=500&auto=format&fit=crop&q=80',
      'isVideo': false,
      'duration': null,
    },
    {
      'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80',
      'isVideo': true,
      'duration': '0:28',
    },
    {
      'url': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=500&auto=format&fit=crop&q=80',
      'isVideo': false,
      'duration': null,
    },
    {
      'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
      'isVideo': true,
      'duration': '0:19',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSelect(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (!_multiSelectEnabled) {
          _selectedIndices.clear();
        }
        _selectedIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF16161A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    Text(
                      'All Media',
                      style: AppTypography.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _multiSelectEnabled = !_multiSelectEnabled);
                    if (!_multiSelectEnabled && _selectedIndices.length > 1) {
                      final first = _selectedIndices.first;
                      _selectedIndices.clear();
                      _selectedIndices.add(first);
                    }
                  },
                  child: Text(
                    _multiSelectEnabled ? 'Multiple' : 'Single',
                    style: AppTypography.bodyMd.copyWith(
                      color: _multiSelectEnabled ? const Color(0xFF5DB8FF) : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Videos'),
              Tab(text: 'Photos'),
            ],
          ),

          // Media Grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(_mockMediaItems),
                _buildGrid(_mockMediaItems.where((item) => item['isVideo'] == true).toList()),
                _buildGrid(_mockMediaItems.where((item) => item['isVideo'] == false).toList()),
              ],
            ),
          ),

          // Bottom Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1E),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedIndices.isEmpty
                      ? 'Select items'
                      : '${_selectedIndices.length} item${_selectedIndices.length > 1 ? 's' : ''} selected',
                  style: AppTypography.bodyMd.copyWith(color: Colors.white70),
                ),
                ElevatedButton(
                  onPressed: _selectedIndices.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Imported ${_selectedIndices.length} item(s) to editor',
                                style: AppTypography.bodyMd.copyWith(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFF1E1E22),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: Text(
                    'Next (${_selectedIndices.length})',
                    style: AppTypography.bodyLg.copyWith(
                      color: _selectedIndices.isEmpty ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIndices.contains(index);

        return GestureDetector(
          onTap: () => _toggleSelect(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item['url'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
                ),
              ),

              if (isSelected)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),

              // Duration badge for videos
              if (item['isVideo'] == true && item['duration'] != null)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['duration'] as String,
                      style: AppTypography.labelCaps.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),

              // Selection Badge
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFFFE2C55) : Colors.black.withValues(alpha: 0.4),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFE2C55) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Text(
                            '${_selectedIndices.toList().indexOf(index) + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
