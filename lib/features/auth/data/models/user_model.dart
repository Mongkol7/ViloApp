class UserModel {
  final int id;
  final String username;
  final String email;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
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
    required this.followersCount,
    required this.followingCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
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
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }
}
