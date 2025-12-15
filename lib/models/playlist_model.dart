class PlaylistModel {
  final String id;
  final String name;
  final String url;
  final DateTime? expiryDate;
  final bool isActive;
  final List<ChannelModel> channels;
  final int totalChannels;
  final DateTime createdAt;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.url,
    this.expiryDate,
    this.isActive = true,
    this.channels = const [],
    this.totalChannels = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
      'channels': channels.map((c) => c.toJson()).toList(),
      'totalChannels': totalChannels,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isActive: json['isActive'] ?? true,
      channels: (json['channels'] as List<dynamic>?)
          ?.map((c) => ChannelModel.fromJson(c))
          .toList() ?? [],
      totalChannels: json['totalChannels'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? url,
    DateTime? expiryDate,
    bool? isActive,
    List<ChannelModel>? channels,
    int? totalChannels,
    DateTime? createdAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      channels: channels ?? this.channels,
      totalChannels: totalChannels ?? this.totalChannels,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PlaylistModel(id: $id, name: $name, url: $url, totalChannels: $totalChannels)';
  }
}