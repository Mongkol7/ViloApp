import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/models/category.dart';

void main() {
  group('ProductCategory Model & Icon Mapping Tests', () {
    test('ProductCategory JSON parsing and serialization', () {
      final json = {
        'id': 'cat-studio',
        'name': 'Studio Equipment',
        'iconName': 'lightbulb',
      };

      final category = ProductCategory.fromJson(json);
      expect(category.id, 'cat-studio');
      expect(category.name, 'Studio Equipment');
      expect(category.iconName, 'lightbulb');

      final serialized = category.toJson();
      expect(serialized['id'], 'cat-studio');
      expect(serialized['name'], 'Studio Equipment');
      expect(serialized['iconName'], 'lightbulb');
    });

    test('Category icon mapping resolution returns valid IconData', () {
      final studio = ProductCategory(id: 'cat-studio', name: 'Studio', iconName: 'lightbulb');
      expect(studio.getIconData(), Icons.lightbulb_outline_rounded);

      final audio = ProductCategory(id: 'cat-audio', name: 'Audio', iconName: 'mic');
      expect(audio.getIconData(), Icons.mic_external_on_rounded);

      final apparel = ProductCategory(id: 'cat-apparel', name: 'Apparel', iconName: 'checkroom');
      expect(apparel.getIconData(), Icons.checkroom_rounded);

      final accessories = ProductCategory(id: 'cat-acc', name: 'Accessories', iconName: 'devices');
      expect(accessories.getIconData(), Icons.devices_other_rounded);

      final lifestyle = ProductCategory(id: 'cat-life', name: 'Lifestyle', iconName: 'shopping_bag');
      expect(lifestyle.getIconData(), Icons.shopping_bag_outlined);

      final merch = ProductCategory(id: 'cat-merch', name: 'Merchandise', iconName: 'style');
      expect(merch.getIconData(), Icons.style_outlined);

      final all = ProductCategory(id: 'cat-all', name: 'All', iconName: 'all');
      expect(all.getIconData(), Icons.grid_view_rounded);

      final fallback = ProductCategory(id: 'cat-unknown', name: 'Other', iconName: 'other');
      expect(fallback.getIconData(), Icons.category_outlined);
    });

    test('Verify defaultCategories contains required creator categories', () {
      final defaultList = ProductCategory.defaultCategories;
      expect(defaultList.isNotEmpty, true);
      expect(defaultList.any((c) => c.name == 'Studio Equipment'), true);
      expect(defaultList.any((c) => c.name == 'Audio & Tech'), true);
      expect(defaultList.any((c) => c.name == 'Apparel'), true);
      expect(defaultList.any((c) => c.name == 'Accessories'), true);
      expect(defaultList.any((c) => c.name == 'Lifestyle'), true);
      expect(defaultList.any((c) => c.name == 'Merchandise'), true);
    });
  });
}
