class PersonSuggestion {
  final String id;
  final String name;
  final String subtitle;
  final String avatarUrl;
  final bool followsYou;
  final bool isFollowed;

  const PersonSuggestion({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    this.followsYou = false,
    this.isFollowed = false,
  });

  PersonSuggestion copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? avatarUrl,
    bool? followsYou,
    bool? isFollowed,
  }) {
    return PersonSuggestion(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followsYou: followsYou ?? this.followsYou,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}
