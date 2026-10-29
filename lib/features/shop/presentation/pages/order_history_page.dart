import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/media_url.dart';
import '../../data/datasources/shop_remote_data_source.dart';
import '../../data/models/order_model.dart';
import '../../models/product.dart';
import '../../../inbox_activity/data/datasources/inbox_message_manager.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<OrderModel>> _ordersFuture;
  final Set<int> _cancellingOrderIds = <int>{};

  @override
  void initState() {
    super.initState();
    _ordersFuture = ShopRemoteDataSource.instance.getOrderHistory();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'PAID':
      case 'DELIVERED':
        return Colors.greenAccent;
      case 'SHIPPED':
        return Colors.blueAccent;
      case 'PENDING':
        return Colors.orangeAccent;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  Future<void> _restoreLegacyOrderItem(OrderItemModel item) async {
    if (item.productId != null) {
      try {
        final restored = await ShopRemoteDataSource.instance
            .restoreProductStock(
              productId: item.productId!,
              quantity: item.quantity,
            );
        Product.setAuthoritativeStock(
          item.productId!.toString(),
          stock: restored.stock,
          productName: item.productTitle,
        );
        Product.deductSoldCount(
          item.productId!.toString(),
          item.quantity,
          productName: item.productTitle,
        );
        return;
      } catch (error) {
        if (error is! ApiResponseException || error.statusCode != 404) {
          rethrow;
        }
      }
    }

    final productKey = item.productId?.toString() ?? item.id.toString();
    Product.restoreStock(
      productKey,
      item.quantity,
      productName: item.productTitle,
    );
    Product.deductSoldCount(
      productKey,
      item.quantity,
      productName: item.productTitle,
    );
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to cancel order ${order.orderNumber}? Stock will be returned immediately.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep Order',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirm Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_cancellingOrderIds.contains(order.id)) return;
      setState(() => _cancellingOrderIds.add(order.id));

      try {
        final isLocalOnlyOrder = order.id > 1000000000000;
        if (isLocalOnlyOrder) {
          for (final item in order.items) {
            try {
              await _restoreLegacyOrderItem(item);
            } catch (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1E1E22),
                    content: Text('Unable to restore stock: $error'),
                  ),
                );
              }
              return;
            }
          }
        } else {
          try {
            await ShopRemoteDataSource.instance.cancelOrder(order.id);
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1E1E22),
                  content: Text('Unable to cancel order: $error'),
                ),
              );
            }
            return;
          }
        }

        for (final it in order.items) {
          await InboxMessageManager.instance.cancelOrderInChats(
            productTitle: it.productTitle,
            orderNumber: order.orderNumber,
            orderId: order.id.toString(),
          );
        }
        ShopRemoteDataSource.instance.updateOrderStatus(
          order.orderNumber,
          'CANCELLED',
        );
        setState(() {
          _ordersFuture = ShopRemoteDataSource.instance.getOrderHistory();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Color(0xFF1E1E22),
              content: const Text(
                'Order cancelled. Stock and order status updated.',
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _cancellingOrderIds.remove(order.id));
        } else {
          _cancellingOrderIds.remove(order.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'When you purchase products, your orders will appear here.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Start Shopping',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              final effectiveStatus = order.dynamicStatus;
              final statusColor = _getStatusColor(effectiveStatus);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              effectiveStatus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 12),

                    // Order Items
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildProductThumbnail(
                                item.productImageUrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.formattedPrice} × ${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                item.formattedSubtotal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),

                    // Order Footer
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Payment: ${order.paymentMethod}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Total: ',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  order.formattedTotal,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (effectiveStatus == 'PENDING') ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _cancellingOrderIds.contains(order.id)
                              ? null
                              : () => _confirmCancelOrder(order),
                          icon: _cancellingOrderIds.contains(order.id)
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFEF4444),
                                  ),
                                )
                              : const Icon(
                                  Icons.cancel_outlined,
                                  size: 14,
                                  color: Color(0xFFEF4444),
                                ),
                          label: Text(
                            _cancellingOrderIds.contains(order.id)
                                ? 'Cancelling...'
                                : 'Cancel Order (Within 4 hrs)',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductThumbnail(String imageUrl) {
    final resolvedImageUrl = resolveBackendMediaUrl(imageUrl);
    if (resolvedImageUrl.startsWith('assets/')) {
      return Image.asset(
        resolvedImageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _thumbnailPlaceholder(),
      );
    }
    if (resolvedImageUrl.startsWith('http')) {
      return Image.network(
        resolvedImageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _thumbnailPlaceholder(),
      );
    }
    return _thumbnailPlaceholder();
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.white12,
      child: const Icon(Icons.image, color: Colors.white24, size: 20),
    );
  }
}
