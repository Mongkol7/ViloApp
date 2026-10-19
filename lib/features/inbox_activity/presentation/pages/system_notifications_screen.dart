import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SystemAlertItem {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  bool isRead;

  SystemAlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    this.actionLabel,
    this.onAction,
    this.isRead = false,
  });
}

class SystemNotificationsScreen extends StatefulWidget {
  const SystemNotificationsScreen({super.key});

  @override
  State<SystemNotificationsScreen> createState() => _SystemNotificationsScreenState();
}

class _SystemNotificationsScreenState extends State<SystemNotificationsScreen> {
  late List<SystemAlertItem> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = [
      SystemAlertItem(
        id: 'sys1',
        title: 'Weekly Screen Time Report',
        description: 'You spent 17% more time on Vilo this week (Daily average 2h 15m). Remember to take breaks!',
        timeAgo: '1h ago',
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(0xFF56CCF2),
        actionLabel: 'View stats',
        isRead: false,
      ),
      SystemAlertItem(
        id: 'sys2',
        title: 'Security Alert: New Login',
        description: 'New login detected from Chrome on Windows 11 • IP: 192.168.1.105. If this was you, no action needed.',
        timeAgo: '5h ago',
        icon: Icons.security_rounded,
        iconColor: const Color(0xFFFE2C55),
        actionLabel: 'Secure account',
        isRead: false,
      ),
      SystemAlertItem(
        id: 'sys3',
        title: 'Creator Engagement Payout',
        description: 'Your monthly creator reward for September is ready for payout review in Creator Hub.',
        timeAgo: '1d ago',
        icon: Icons.monetization_on_rounded,
        iconColor: const Color(0xFF27AE60),
        actionLabel: 'Check payout',
        isRead: true,
      ),
      SystemAlertItem(
        id: 'sys4',
        title: 'Vilo v2.4 Update is Live',
        description: 'Enjoy 24h thought stories with high quality audio waveforms, trim controls, and swipe navigation.',
        timeAgo: '2d ago',
        icon: Icons.rocket_launch_rounded,
        iconColor: const Color(0xFF9B51E0),
        actionLabel: "What's new",
        isRead: true,
      ),
      SystemAlertItem(
        id: 'sys5',
        title: 'Community Guidelines Refresh',
        description: 'We have updated our Community Guidelines to provide better creator protection and privacy.',
        timeAgo: '4d ago',
        icon: Icons.policy_rounded,
        iconColor: const Color(0xFF8E8E93),
        actionLabel: 'Read rules',
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (final a in _alerts) {
        a.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All system notifications marked as read'),
        backgroundColor: Color(0xFF2F80ED),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showScreenTimeDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SingleChildScrollView(
        child: Material(
          color: const Color(0xFF1E1E22),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF48484E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Weekly Screen Time',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Oct 12 - Oct 18 • 17% increase vs last week',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 20),
              // Daily Bar Chart Simulation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar('Mon', 0.4),
                    _buildBar('Tue', 0.6),
                    _buildBar('Wed', 0.5),
                    _buildBar('Thu', 0.75),
                    _buildBar('Fri', 0.9, isHighlight: true),
                    _buildBar('Sat', 0.85),
                    _buildBar('Sun', 0.7),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF27AE60), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Daily average: 2h 15m (Within healthy goal)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD1D1D6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  static Widget _buildBar(String day, double heightFraction, {bool isHighlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 90 * heightFraction,
          decoration: BoxDecoration(
            color: isHighlight ? const Color(0xFF2F80ED) : const Color(0xFF33333C),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            color: isHighlight ? const Color(0xFF2F80ED) : const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  void _showAlertDetail(SystemAlertItem alert) {
    setState(() => alert.isRead = true);
    if (alert.id == 'sys1') {
      _showScreenTimeDetail();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(alert.icon, color: alert.iconColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alert.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          alert.description,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFFD1D1D6),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Action confirmed for ${alert.title}'),
                  backgroundColor: const Color(0xFF2F80ED),
                ),
              );
            },
            child: Text(alert.actionLabel ?? 'OK', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: AppColors.voidBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: const Text(
          'System notifications',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Read all',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F80ED),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Weekly Highlight Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: _showScreenTimeDetail,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2838), Color(0xFF16161A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF56CCF2).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF56CCF2).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF56CCF2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Screen Time',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'You spent 17% more time this week • Tap to view daily breakdown',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF9E9EA4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF8E8E93),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'RECENT ALERTS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 1.1,
              ),
            ),
          ),

          ...List.generate(_alerts.length, (index) {
            final alert = _alerts[index];
            return InkWell(
              onTap: () => _showAlertDetail(alert),
              splashColor: Colors.white.withValues(alpha: 0.05),
              child: Container(
                color: alert.isRead ? Colors.transparent : const Color(0xFF2F80ED).withValues(alpha: 0.04),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: alert.iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(alert.icon, color: alert.iconColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert.title,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: alert.isRead ? FontWeight.w600 : FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                alert.timeAgo,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.description,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFFB0B0B8),
                              height: 1.3,
                            ),
                          ),
                          if (alert.actionLabel != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showAlertDetail(alert),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A32),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF3A3A44)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      alert.actionLabel!,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF56CCF2),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF56CCF2),
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!alert.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2F80ED),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
