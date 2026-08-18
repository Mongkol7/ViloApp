import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Balance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, color: Colors.green, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Secure',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Estimated Balance Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Estimated balance USD',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                const Icon(Icons.visibility_outlined, color: Colors.grey, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '0.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.grey[600], size: 40),
              ],
            ),
            const SizedBox(height: 20),
            
            // Coins Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.orange,
                    child: Text('d', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Coins', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 4),
                  const Text('0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 15, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 16),
                  const SizedBox(width: 4),
                  const Text('Get Coins', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.pinkAccent, size: 16),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Transactions Card
            _buildActionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text('View all', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                    ],
                  ),
                ],
              ),
            ),
            
            // Recharge Offer Card
            _buildActionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'First recharge offer',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get Gifts and bonus Coins',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 32),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Services Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Services',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildServiceItem(Icons.account_balance_wallet, 'LIVE rewards'),
                  _buildServiceItem(Icons.bar_chart, 'Monetisation'),
                  _buildServiceItem(Icons.calendar_today, 'Subscriptions\nManager'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildServiceItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}
