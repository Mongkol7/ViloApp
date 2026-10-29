import '../../../../core/network/media_url.dart';

class UserModel {
  final int id;
  final String username;
  final String email;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
  final bool isFollowing;
  final bool followsYou;
  final int followersCount;
  final int followingCount;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.isVerified,
    this.isFollowing = false,
    this.followsYou = false,
    required this.followersCount,
    required this.followingCount,
  });

  static String? _resolveAvatarUrl(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    final clean = value.toString().trim();
    return resolveBackendMediaUrl(clean);
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isVerified,
    bool? isFollowing,
    bool? followsYou,
    int? followersCount,
    int? followingCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isFollowing: isFollowing ?? this.isFollowing,
      followsYou: followsYou ?? this.followsYou,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarUrl: _resolveAvatarUrl(json['avatarUrl']),
      isVerified: json['isVerified'] as bool? ?? false,
      isFollowing: json['isFollowing'] as bool? ?? false,
      followsYou: json['followsYou'] as bool? ?? false,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'isFollowing': isFollowing,
      'followsYou': followsYou,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }
}
