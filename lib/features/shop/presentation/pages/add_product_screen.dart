import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../services/shop_service.dart';

/// Screen allowing creators and merchants to list new products for sale.
///
/// Features rich dark-mode aesthetics, required field validations, category chip selection,
/// visual image presets with custom URL override, and instant catalog synchronization.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(text: '10');
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _sellerController = TextEditingController(text: '@ViloCreator');
  final TextEditingController _customImageController = TextEditingController();

  static const List<Map<String, String>> _categories = [
    {'id': 'cat-tech', 'name': 'Tech & Gadgets'},
    {'id': 'cat-fashion', 'name': 'Fashion & Apparel'},
    {'id': 'cat-beauty', 'name': 'Beauty & Care'},
    {'id': 'cat-studio', 'name': 'Studio Equipment'},
    {'id': 'cat-acc', 'name': 'Accessories'},
    {'id': 'cat-life', 'name': 'Lifestyle'},
  ];

  static const List<String> _presetImages = [
    'assets/images/v_watch_ultra.jpg',
    'assets/images/canvas_tote.jpg',
    'assets/images/v_series_headphones.jpg',
    'assets/images/obsidian_hoodie.jpg',
    'assets/images/pocket_fill_light.jpg',
    'assets/images/midnight_hydration_serum.jpg',
    'assets/images/mini_rice_cooker.jpg',
    'assets/images/iphone_17_pro_max_case.jpg',
  ];

  late String _selectedCategoryId;
  late String _selectedCategoryName;
  late String _selectedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = _categories.first['id']!;
    _selectedCategoryName = _categories.first['name']!;
    _selectedImage = _presetImages.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _sellerController.dispose();
    _customImageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final title = _titleController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final origPriceText = _originalPriceController.text.trim();
    final double? origPrice = origPriceText.isNotEmpty ? double.tryParse(origPriceText) : null;
    final stock = int.tryParse(_stockController.text.trim()) ?? 10;
    final desc = _descController.text.trim();
    var seller = _sellerController.text.trim();
    if (seller.isEmpty) seller = '@ViloCreator';
    if (!seller.startsWith('@')) seller = '@$seller';

    final customImg = _customImageController.text.trim();
    final imageToUse = customImg.isNotEmpty ? customImg : _selectedImage;

    final newProduct = Product(
      id: 'prod_seller_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      categoryId: _selectedCategoryId,
      category: _selectedCategoryName,
      price: price,
      originalPrice: origPrice,
      description: desc,
      imageUrl: imageToUse,
      seller: seller,
      rating: 5.0,
      soldCount: 0,
      badge: 'NEW',
    );

    // Register with in-memory ShopService catalog
    ShopService.instance.addProduct(newProduct);

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white12),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🎉 Product "$title" published for sale!',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.pop(context, newProduct);
  }

  @override
  Widget build(BuildContext context) {
    const inputFillColor = Color(0xFF1C1C1E);
    const borderColor = Color(0xFF2C2C2E);

    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: AppColors.voidBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sell Product',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Card ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2F80ED).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'List New Product to Sell',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Publish your item directly into the Vilo Store',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Product Title * ──────────────────────────────────────
              _buildSectionLabel('Product Title *'),
              TextFormField(
                key: const Key('add_product_title_field'),
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                decoration: _inputDecoration(
                  hintText: 'e.g. Vilo Minimalist Wireless Headphones',
                  fillColor: inputFillColor,
                  borderColor: borderColor,
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Product title is required';
                  if (v.trim().length < 3) return 'Title must be at least 3 characters';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // ── Category Selection * ─────────────────────────────────
              _buildSectionLabel('Category *'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat['id'];
                  return ChoiceChip(
                    label: Text(cat['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategoryId = cat['id']!;
                          _selectedCategoryName = cat['name']!;
                        });
                      }
                    },
                    backgroundColor: const Color(0xFF1C1C1E),
                    selectedColor: const Color(0xFF2F80ED),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2F80ED) : Colors.white12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // ── Price & Original Price ───────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Price (\$) *'),
                        TextFormField(
                          key: const Key('add_product_price_field'),
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 14.5),
                          decoration: _inputDecoration(
                            hintText: '49.99',
                            fillColor: inputFillColor,
                            borderColor: borderColor,
                            prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF10B981), size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Price required';
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Original Price (\$)'),
                        TextFormField(
                          controller: _originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 14.5),
                          decoration: _inputDecoration(
                            hintText: '69.99 (Optional)',
                            fillColor: inputFillColor,
                            borderColor: borderColor,
                            prefixIcon: const Icon(Icons.money_off_rounded, color: Colors.white38, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Stock Quantity * ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Stock Quantity *'),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14.5),
                          decoration: _inputDecoration(
                            hintText: '10',
                            fillColor: inputFillColor,
                            borderColor: borderColor,
                            prefixIcon: const Icon(Icons.inventory_2_outlined, color: Colors.white38, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Stock required';
                            final parsed = int.tryParse(v.trim());
                            if (parsed == null || parsed < 0) return 'Invalid stock';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Seller Name *'),
                        TextFormField(
                          controller: _sellerController,
                          style: const TextStyle(color: Colors.white, fontSize: 14.5),
                          decoration: _inputDecoration(
                            hintText: '@MyStore',
                            fillColor: inputFillColor,
                            borderColor: borderColor,
                            prefixIcon: const Icon(Icons.verified_outlined, color: Color(0xFF2F80ED), size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Seller required';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Product Image Selector * ─────────────────────────────
              _buildSectionLabel('Product Image *'),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _presetImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final img = _presetImages[index];
                    final isSelected = _selectedImage == img && _customImageController.text.trim().isEmpty;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = img;
                          _customImageController.clear();
                        });
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2F80ED) : Colors.white12,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white10,
                                  child: const Icon(Icons.image, color: Colors.white38),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Custom Image URL fallback
              TextFormField(
                controller: _customImageController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDecoration(
                  hintText: 'Or enter custom image URL (optional)',
                  fillColor: inputFillColor,
                  borderColor: borderColor,
                  prefixIcon: const Icon(Icons.link_rounded, color: Colors.white38, size: 18),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 18),

              // ── Description * ────────────────────────────────────────
              _buildSectionLabel('Product Description *'),
              TextFormField(
                key: const Key('add_product_desc_field'),
                controller: _descController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                decoration: _inputDecoration(
                  hintText: 'Detail the features, technical specs, build quality, and what makes this product unique...',
                  fillColor: inputFillColor,
                  borderColor: borderColor,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.trim().length < 8) return 'Description must be at least 8 characters';
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // ── Submit Button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('add_product_publish_btn'),
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: const Color(0xFF2F80ED).withValues(alpha: 0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.publish_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Publish Product to Sell',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Color fillColor,
    required Color borderColor,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      filled: true,
      fillColor: fillColor,
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2F80ED), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
