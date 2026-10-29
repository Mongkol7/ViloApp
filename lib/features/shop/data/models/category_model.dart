import '../../../../core/network/media_url.dart';

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? iconUrl;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconUrl: resolveBackendMediaUrl(json['iconUrl'] as String?),
      imageUrl: resolveBackendMediaUrl(json['imageUrl'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
    };
  }
}
