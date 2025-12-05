class Channel {
  final int id;
  final String name;
  final String link;
  final String category;
  final String image;

  const Channel({
    required this.id,
    required this.name,
    required this.link,
    required this.category,
    required this.image,
  });

  factory Channel.fromMap(Map<String, dynamic> m) {
    return Channel(
      id: (m['id'] as int),
      name: (m['channel_name'] ?? '').toString(),
      link: (m['channel_link'] ?? '').toString(),
      category: (m['channel_categories'] ?? '').toString(),
      image: (m['channel_image'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channel_name': name,
      'channel_link': link,
      'channel_categories': category,
      'channel_image': image,
    };
  }
}
