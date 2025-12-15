class ChannelModel {
  final String name;
  final String url;
  final String groupTitle;
  final String? logo;
  final String? category;

  ChannelModel({
    required this.name,
    required this.url,
    required this.groupTitle,
    this.logo,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'groupTitle': groupTitle,
      'logo': logo,
      'category': category,
    };
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      groupTitle: json['groupTitle'] ?? '',
      logo: json['logo'],
      category: json['category'],
    );
  }

  ChannelModel copyWith({
    String? name,
    String? url,
    String? groupTitle,
    String? logo,
    String? category,
  }) {
    return ChannelModel(
      name: name ?? this.name,
      url: url ?? this.url,
      groupTitle: groupTitle ?? this.groupTitle,
      logo: logo ?? this.logo,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'ChannelModel(name: $name, url: $url, groupTitle: $groupTitle)';
  }
}