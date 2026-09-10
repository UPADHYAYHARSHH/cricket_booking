class SupportAction {
  final String type;
  final String label;
  final String? url;
  final String? bookingId;

  SupportAction({
    required this.type,
    required this.label,
    this.url,
    this.bookingId,
  });

  factory SupportAction.fromJson(Map<String, dynamic> json) {
    return SupportAction(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      url: json['url']?.toString(),
      bookingId: json['booking_id']?.toString(),
    );
  }
}

class SupportMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> quickReplies;
  final List<SupportAction> actions;

  SupportMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies = const [],
    this.actions = const [],
  });

  factory SupportMessageModel.bot({
    required String text,
    List<String> quickReplies = const [],
    List<SupportAction> actions = const [],
  }) {
    return SupportMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
      actions: actions,
    );
  }

  factory SupportMessageModel.user({required String text}) {
    return SupportMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }
}
