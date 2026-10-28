import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/auth/data/models/user_model.dart';
import 'package:viloapp/features/feed/presentation/widgets/create_action_sheet.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/chat_detail_screen.dart';
import 'package:viloapp/features/profile/data/datasources/profile_sync_service.dart';
import 'package:viloapp/features/profile/presentation/widgets/profile_tab_content.dart';
import 'package:viloapp/features/profile/presentation/widgets/shop_product_card.dart';
import 'package:viloapp/features/shop/models/product.dart';
import 'package:viloapp/features/shop/presentation/pages/product_detail_page.dart';
import 'package:viloapp/features/shop/views/product_detail_screen.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/inbox_message_manager.dart';
import 'package:viloapp/features/shop/presentation/controllers/cart_controller.dart';
import 'package:viloapp/features/shop/data/models/product_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreateActionPopupCard UI and Animations', () {
    testWidgets('CreateActionPopupCard renders all 4 actions with compact width',
        (WidgetTester tester) async {
      bool cameraTapped = false;
      bool videoTapped = false;
      bool soundTapped = false;
      bool productTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  right: 14,
                  bottom: 100,
                  child: CreateActionPopupCard(
                    onCameraSelected: () => cameraTapped = true,
                    onUploadSelected: () => videoTapped = true,
                    onUploadSoundSelected: () => soundTapped = true,
                    onPostProductSelected: () => productTapped = true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 4 action pills are visible in the popup card
      expect(find.byType(CreateActionPopupCard), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Upload Video'), findsOneWidget);
      expect(find.text('Upload Music / Sound'), findsOneWidget);
      expect(find.text('Post Product'), findsOneWidget);

      // Verify card layout & positioning: compact width of 204
      final cardRect = tester.getRect(find.byType(CreateActionPopupCard));
      expect(cardRect.width, 204);

      // Tap "Upload Video" and verify callback is invoked
      await tester.tap(find.text('Upload Video'));
      await tester.pumpAndSettle();
      expect(videoTapped, isTrue);

      // Tap "Upload Music / Sound" and verify callback is invoked
      await tester.tap(find.text('Upload Music / Sound'));
      await tester.pumpAndSettle();
      expect(soundTapped, isTrue);

      // Tap "Post Product" and verify callback is invoked
      await tester.tap(find.text('Post Product'));
      await tester.pumpAndSettle();
      expect(productTapped, isTrue);

      // Tap "Camera" and verify callback is invoked
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(cameraTapped, isTrue);
    });
  });

  group('Post Product -> Product Detail Screen Flow', () {
    testWidgets('ProductDetailScreen displays custom post product info (title, category, stock, desc)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const customProduct = Product(
        id: 'prod-custom-99',
        name: 'Handcrafted Vintage Leather Backpack',
        categoryId: 'cat-fashion',
        category: 'Fashion',
        price: 89.99,
        originalPrice: 129.99,
        rating: 4.95,
        soldCount: 38,
        stock: 15,
        seller: 'sereymongkol',
        description: 'Premium full-grain Italian leather backpack with brass hardware and laptop sleeve.',
        imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductDetailScreen(product: customProduct),
        ),
      );
      await tester.pumpAndSettle();

      // Verify custom title & prices
      expect(find.text('Handcrafted Vintage Leather Backpack'), findsWidgets);
      expect(find.text('\$89.99'), findsOneWidget);
      expect(find.text('\$129.99'), findsOneWidget);
      expect(find.text('-31% OFF'), findsOneWidget);

      // Verify description section contains custom description, category, and stock
      expect(find.textContaining('Premium full-grain Italian leather'), findsOneWidget);
      expect(find.text('Category: Fashion'), findsOneWidget);
      expect(find.text('Stock: 15 units'), findsOneWidget);
      expect(find.text('Seller: sereymongkol'), findsOneWidget);
    });
  });

  group('ShopProductCard & Direct Message Flow', () {
    testWidgets('ShopProductCard renders custom product and Send Message button pushes ChatDetailScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const customProduct = Product(
        id: 'prod-artisan-1',
        name: 'Mechanical Keyboard Artisan Keycap',
        categoryId: 'cat-tech',
        category: 'Gaming',
        price: 45.00,
        originalPrice: 60.00,
        rating: 4.9,
        soldCount: 12,
        stock: 5,
        seller: 'craftsman_bob',
        description: 'Hand-painted resin artisan keycap featuring Mt. Fuji sakura landscape.',
        imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShopProductCard(
                product: customProduct,
                sellerUsername: 'craftsman_bob',
                isCurrentUser: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify custom card contents
      expect(find.text('Mechanical Keyboard Artisan Keycap'), findsOneWidget);
      expect(find.text('\$45.00'), findsOneWidget);
      expect(find.text('\$60.00'), findsOneWidget);
      expect(find.text('-25%'), findsOneWidget);
      expect(find.text('By @craftsman_bob'), findsOneWidget);
      expect(find.text('Send Message'), findsOneWidget);

      // Tap "Send Message"
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();

      // Verify navigation to ChatDetailScreen
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('@craftsman_bob'), findsWidgets);
    });

    testWidgets('Tapping ShopProductCard opens ProductDetailPage with all passed info',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const customProduct = Product(
        id: 'prod-artisan-2',
        name: 'Retro Mechanical Watch',
        categoryId: 'cat-accessories',
        category: 'Accessories',
        price: 199.99,
        originalPrice: 249.99,
        rating: 5.0,
        soldCount: 7,
        stock: 3,
        seller: 'craftsman_bob',
        description: 'Hand-assembled mechanical movement watch with sapphire crystal.',
        imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShopProductCard(
                product: customProduct,
                sellerUsername: 'craftsman_bob',
                isCurrentUser: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the card
      await tester.tap(find.text('Retro Mechanical Watch'));
      await tester.pumpAndSettle();

      // Verify ProductDetailPage and ProductDetailScreen opened
      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Retro Mechanical Watch'), findsWidgets);
      expect(find.text('\$199.99'), findsOneWidget);
      expect(find.text('Category: Accessories'), findsOneWidget);
      expect(find.text('Stock: 3 units'), findsOneWidget);
    });

    testWidgets('Owner viewing ShopProductCard sees "Your Product" and tapping shows 2-second alert',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const ownedProduct = Product(
        id: 'prod-mine-1',
        name: 'My Custom Wireless Earbuds',
        categoryId: 'cat-audio',
        category: 'Audio',
        price: 79.99,
        imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800',
        description: 'High fidelity audio earbuds with active noise cancellation.',
        seller: 'mongkol',
        sellerId: '1',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShopProductCard(
                product: ownedProduct,
                sellerUsername: 'mongkol',
                isCurrentUser: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Your Product" chip is displayed instead of "Send Message"
      expect(find.text('Your Product'), findsOneWidget);
      expect(find.text('Send Message'), findsNothing);

      // Tap "Your Product"
      await tester.tap(find.text('Your Product'));
      await tester.pump();

      // Verify 2-second alert message appears
      expect(
        find.text('This is your posted product. You cannot send a message to yourself or add to cart.'),
        findsOneWidget,
      );
    });

    testWidgets('Owner viewing ProductDetailScreen sees "Your Product" in sticky bottom bar and alerts on tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        ProfileSyncService.instance.clear();
      });

      // Log in as owner ("mongkol", id: 1)
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 1,
        username: 'mongkol',
        displayName: 'Mongkol',
        email: 'mongkol@vilo.app',
        isVerified: true,
        followersCount: 10,
        followingCount: 5,
      );

      const ownedProduct = Product(
        id: 'prod-mine-2',
        name: 'My Custom Mechanical Keyboard',
        categoryId: 'cat-tech',
        category: 'Tech',
        price: 159.00,
        imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800',
        seller: 'mongkol',
        sellerId: '1',
        description: 'My custom built mechanical keyboard.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductDetailScreen(
              product: ownedProduct,
              seller: 'mongkol',
              sellerId: '1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sticky bar should display "Your Product"
      expect(find.text('Your Product'), findsWidgets);
      expect(find.text('Add to Cart'), findsNothing);

      // Tapping "Your Product" triggers the 2-second cart alert
      await tester.tap(find.text('Your Product').last);
      await tester.pump();
      expect(
        find.text('Unable to add to cart. This is your own posted product.'),
        findsOneWidget,
      );

      // Tapping "Send Message" triggers the 2-second message alert
      await tester.tap(find.text('Send Message').last);
      await tester.pump();
      expect(
        find.text('This is your posted product. You cannot send a message to yourself.'),
        findsOneWidget,
      );
    });

    testWidgets('Non-owner (logged into another account) viewing other user product sees Add to Cart and Send Message',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        ProfileSyncService.instance.clear();
      });

      // Log in as user 2 ("serey")
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 2,
        username: 'serey',
        displayName: 'Serey Dev',
        email: 'serey@vilo.app',
        isVerified: false,
        followersCount: 10,
        followingCount: 5,
      );

      // Other user's ("mongkol", id: 1) product
      const otherProduct = Product(
        id: 'prod-mongkol-1',
        name: 'Mongkol Premium Headset',
        categoryId: 'cat-audio',
        category: 'Audio',
        price: 199.00,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
        seller: 'mongkol',
        sellerId: '1',
        description: 'Flagship studio monitor headphones with spatial audio.',
      );

      // 1. Verify in ShopProductCard (e.g. from public profile)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShopProductCard(
                product: otherProduct,
                sellerUsername: 'mongkol',
                isCurrentUser: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Send Message'), findsOneWidget);
      expect(find.text('Your Product'), findsNothing);

      // 2. Verify in ProductDetailScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductDetailScreen(
              product: otherProduct,
              seller: 'mongkol',
              sellerId: '1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bottom bar must display "Add to Cart" and "Send Message", NOT "Your Product"
      expect(find.text('Add to Cart'), findsWidgets);
      expect(find.text('Your Product'), findsNothing);
      expect(find.text('Send Message'), findsWidgets);
    });

    testWidgets('Single product post immediately shows in profile shop tab without requiring a second product',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        ProfileSyncService.instance.clear();
      });

      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 1,
        username: 'mongkol',
        displayName: 'Mongkol',
        email: 'mongkol@vilo.app',
        isVerified: true,
        followersCount: 10,
        followingCount: 5,
      );

      final rebuildNotifier = ValueNotifier<int>(0);
      ProfileSyncService.instance.productUploadedEvents.addListener(() {
        rebuildNotifier.value++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: rebuildNotifier,
              builder: (context, _, _) {
                return CustomScrollView(
                  slivers: buildProfileTabSlivers(
                    2, // Shop tab
                    isCurrentUser: true,
                    username: 'mongkol',
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const newProduct = Product(
        id: 'prod-first-single-1',
        name: 'Single Posted Artisan Keyboard',
        categoryId: 'cat-tech',
        category: 'Tech',
        price: 180.00,
        imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800',
        seller: 'mongkol',
        sellerId: '1',
        description: 'High quality artisan keyboard.',
      );

      Product.addCreatorProduct(newProduct);
      ProfileSyncService.instance.productUploadedEvents.value = newProduct;

      await tester.pumpAndSettle();

      // The single product must immediately be visible in the profile shop tab!
      expect(find.text('Single Posted Artisan Keyboard'), findsOneWidget);
      expect(find.text('Your Product'), findsOneWidget);
    });

    testWidgets('Buyer buying via Send Message forwards product image and deducts stock in real time',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Product.resetStockOverrides();
        ProfileSyncService.instance.clear();
      });

      // Seller is @seller_sam, buyer is @buyer_bob
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 2,
        username: 'buyer_bob',
        displayName: 'Buyer Bob',
        email: 'bob@vilo.app',
        avatarUrl: 'https://images.unsplash.com/photo-buyer.jpg',
        isVerified: true,
        followersCount: 10,
        followingCount: 5,
      );

      Product.resetStockOverrides();
      const product = Product(
        id: 'prod-stock-test-1',
        name: 'Wireless Mechanical Keyboard',
        categoryId: 'cat-tech',
        price: 99.0,
        stock: 3,
        imageUrl: 'https://images.unsplash.com/photo-keyboard.jpg',
        seller: 'seller_sam',
        sellerId: '99',
        description: 'Great mechanical keyboard.',
      );

      // Verify initial effective stock is 3
      expect(Product.getEffectiveStock('prod-stock-test-1', 3), 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShopProductCard(
              product: product,
              sellerUsername: 'seller_sam',
              isCurrentUser: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify card is fully opaque
      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsWidgets);
      final opacityWidget = tester.widget<Opacity>(opacityFinder.first);
      expect(opacityWidget.opacity, 1.0);

      // Verify "Send Message" button is available
      expect(find.text('Send Message'), findsOneWidget);

      // Buyer taps "Send Message" to order
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();

      // 1. Stock should be deducted in real time from 3 to 2
      expect(Product.getEffectiveStock('prod-stock-test-1', 3), 2);

      // 2. Thread was registered with canonical ID and initial message forwarded image
      final threadId = InboxMessageManager.buildThreadId('buyer_bob', 'seller_sam');
      final thread = InboxMessageManager.instance.getThread(threadId);
      expect(thread, isNotNull);
      expect(thread!.messages.isNotEmpty, isTrue);
      expect(thread.messages.first.imageUrl, 'https://images.unsplash.com/photo-keyboard.jpg');

      // 3. For seller's view: when seller_sam inspects this thread, resolveThreadForActiveUser shows buyer's username/avatar
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 99,
        username: 'seller_sam',
        displayName: 'Seller Sam',
        email: 'sam@vilo.app',
        avatarUrl: 'https://images.unsplash.com/photo-seller.jpg',
        isVerified: true,
        followersCount: 50,
        followingCount: 10,
      );
      final sellerPerspectiveThread = InboxMessageManager.resolveThreadForActiveUser(thread);
      expect(sellerPerspectiveThread.username, '@buyer_bob');
      expect(sellerPerspectiveThread.avatarUrl, 'https://images.unsplash.com/photo-buyer.jpg');
    });

    testWidgets('Out of stock product dents opacity, shows Out of Stock badge, and blocks ordering',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Product.resetStockOverrides();
        ProfileSyncService.instance.clear();
      });

      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 2,
        username: 'buyer_bob',
        displayName: 'Buyer Bob',
        email: 'bob@vilo.app',
        isVerified: true,
        followersCount: 10,
        followingCount: 5,
      );

      Product.resetStockOverrides();
      const product = Product(
        id: 'prod-out-of-stock-1',
        name: 'Limited Edition Retro Camera',
        categoryId: 'cat-tech',
        price: 450.0,
        stock: 1,
        imageUrl: 'https://images.unsplash.com/photo-camera.jpg',
        seller: 'seller_sam',
        sellerId: '99',
        description: 'Classic vintage retro film camera.',
      );

      // Deduct the only 1 item in stock to reach 0
      Product.deductStock('prod-out-of-stock-1', 1, initialStock: 1);
      expect(Product.getEffectiveStock('prod-out-of-stock-1', 1), 0);
      expect(product.isOutOfStock, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShopProductCard(
              product: product,
              sellerUsername: 'seller_sam',
              isCurrentUser: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify card opacity is dented to 0.55
      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacityWidget.opacity, 0.55);

      // 2. Verify "Out of Stock" badge is shown
      expect(find.text('Out of Stock'), findsWidgets);

      // 3. Tapping Out of Stock button shows alert and does not allow ordering
      await tester.tap(find.text('Out of Stock').last);
      await tester.pumpAndSettle();

      expect(find.text('This product is currently out of stock and cannot be ordered.'), findsOneWidget);

      // 4. In CartController, cannot add out of stock product
      const productModel = ProductModel(
        id: 99999,
        title: 'Limited Edition Retro Camera',
        description: 'Classic vintage retro film camera.',
        price: 450.0,
        stock: 0,
        rating: 4.8,
        reviewCount: 10,
        salesCount: 5,
      );
      final canAdd = await CartController.instance.addToCart(productModel);
      expect(canAdd, isFalse);
    });

    testWidgets('Buyer clicking Send Message displays correct seller profile avatar, and seller inbox displays correct buyer username and avatar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        ProfileSyncService.instance.clear();
      });

      // 1. Setup buyer account
      const buyerAvatarUrl = 'https://images.unsplash.com/photo-buyer-avatar.jpg';
      const sellerAvatarUrl = 'https://images.unsplash.com/photo-seller-avatar.jpg';

      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 777,
        username: 'buyer_alice',
        displayName: 'Alice Buyer',
        email: 'alice@vilo.app',
        avatarUrl: buyerAvatarUrl,
        isVerified: true,
        followersCount: 50,
        followingCount: 20,
      );

      const product = Product(
        id: 'prod-handcrafted-mug',
        name: 'Handcrafted Ceramic Mug',
        categoryId: 'cat-home',
        price: 35.0,
        stock: 5,
        imageUrl: 'https://images.unsplash.com/photo-ceramic-mug.jpg',
        seller: 'mongkol',
        sellerAvatar: sellerAvatarUrl,
        sellerId: '1',
        description: 'Artisanal ceramic coffee mug.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShopProductCard(
              product: product,
              sellerUsername: 'mongkol',
              sellerAvatarUrl: sellerAvatarUrl,
              isCurrentUser: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Buyer clicks "Send Message"
      expect(find.text('Send Message'), findsOneWidget);
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();

      // 3. Verify ChatDetailScreen opened with seller handle in AppBar
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('@mongkol'), findsOneWidget);

      // Verify thread registered with correct buyer and seller details
      final threadId = InboxMessageManager.buildThreadId('buyer_alice', '@mongkol');
      final buyerViewThread = InboxMessageManager.instance.getThread(threadId);
      expect(buyerViewThread, isNotNull);
      expect(buyerViewThread!.username, '@mongkol');
      expect(buyerViewThread.avatarUrl, sellerAvatarUrl);
      expect(buyerViewThread.senderHandle, '@buyer_alice');
      expect(buyerViewThread.senderAvatar, buyerAvatarUrl);
      expect(buyerViewThread.recipientHandle, '@mongkol');
      expect(buyerViewThread.recipientAvatar, sellerAvatarUrl);
      expect(buyerViewThread.messages.first.isMe, isTrue);

      // 4. Now simulate seller ('mongkol') logging in and viewing the inbox
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 1,
        username: 'mongkol',
        displayName: 'Mongkol Seller',
        email: 'mongkol@vilo.app',
        avatarUrl: sellerAvatarUrl,
        isVerified: true,
        followersCount: 120,
        followingCount: 80,
      );

      // Thread resolved for seller must invert to the buyer's username and buyer's avatar
      final sellerViewThread = InboxMessageManager.instance.getThread(threadId);
      expect(sellerViewThread, isNotNull);
      expect(sellerViewThread!.username, '@buyer_alice');
      expect(sellerViewThread.avatarUrl, buyerAvatarUrl);
      // For seller, the message sent by buyer has isMe == false
      expect(sellerViewThread.messages.first.isMe, isFalse);

      // Pop buyer's pushed chat screen
      Navigator.of(tester.element(find.byType(ChatDetailScreen))).pop();
      await tester.pumpAndSettle();

      // 5. When seller opens ChatDetailScreen with sellerViewThread:
      await tester.pumpWidget(
        MaterialApp(
          home: ChatDetailScreen(thread: sellerViewThread),
        ),
      );
      await tester.pumpAndSettle();

      // The AppBar shows the buyer's username '@buyer_alice'
      expect(find.text('@buyer_alice'), findsOneWidget);
      // The incoming message inquiry is displayed
      expect(find.textContaining('Hi! I would like to order Handcrafted Ceramic Mug'), findsOneWidget);
    });
  });
}
