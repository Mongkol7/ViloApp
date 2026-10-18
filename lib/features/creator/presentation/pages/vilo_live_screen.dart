import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';

class ViloLiveScreen extends StatefulWidget {
  const ViloLiveScreen({super.key});

  @override
  State<ViloLiveScreen> createState() => _ViloLiveScreenState();
}

class _ViloLiveScreenState extends State<ViloLiveScreen> {
  final _titleController = TextEditingController(text: 'Chilling & Connecting with the City 🌃');
  String _selectedTopic = 'Chatting';
  bool _isLive = false;
  int _viewerCount = 142;

  final List<String> _topics = ['Chatting', 'Gaming', 'Music', 'Vlog', 'Fashion', 'Art'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _startLive() {
    HapticFeedback.heavyImpact();
    setState(() => _isLive = true);
  }

  void _stopLive() {
    HapticFeedback.mediumImpact();
    setState(() => _isLive = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('LIVE stream ended', style: AppTypography.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E22),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Viewfinder
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF181820),
                    Color(0xFF0F0F14),
                    Colors.black,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.sensors_rounded,
                  size: 96,
                  color: _isLive
                      ? const Color(0xFFFE2C55).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),

            // Top Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE2C55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.white, size: 10),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE • $_viewerCount viewers',
                            style: AppTypography.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Live Broadcast Setup',
                      style: AppTypography.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 26),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ),
            ),

            // Broadcast Setup Card (if not live)
            if (!_isLive)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: Colors.white70, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              style: AppTypography.bodyLg.copyWith(color: Colors.white),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Add a title to your LIVE stream...',
                                hintStyle: TextStyle(color: Colors.white38),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      Text('Topic', style: AppTypography.labelCaps.copyWith(color: Colors.white70)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _topics.map((topic) {
                            final isSel = _selectedTopic == topic;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTopic = topic),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  topic,
                                  style: AppTypography.bodyMd.copyWith(
                                    color: isSel ? Colors.black : Colors.white,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Action Button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24,
              right: 24,
              child: ElevatedButton(
                onPressed: _isLive ? _stopLive : _startLive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLive ? const Color(0xFF222226) : const Color(0xFFFE2C55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isLive ? Icons.stop_rounded : Icons.sensors_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLive ? 'End LIVE Broadcast' : 'Go LIVE Now',
                      style: AppTypography.headlineSm.copyWith(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
