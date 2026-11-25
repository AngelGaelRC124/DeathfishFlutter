class RadioStation {
  const RadioStation({
    required this.isLive,
    required this.streamUrl,
    required this.programTitle,
    required this.listenersCount,
  });

  const RadioStation.offline()
    : isLive = false,
      streamUrl = '',
      programTitle = '',
      listenersCount = 0;

  final bool isLive;
  final String streamUrl;
  final String programTitle;
  final int listenersCount;

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
    isLive: json['isLive'] as bool? ?? false,
    streamUrl: json['streamUrl'] as String? ?? '',
    programTitle: json['programTitle'] as String? ?? '',
    listenersCount: json['listenersCount'] as int? ?? 0,
  );
}

class RadioChatMessage {
  const RadioChatMessage({
    required this.author,
    required this.message,
    this.createdAt,
  });

  final String author;
  final String message;
  final DateTime? createdAt;
}
