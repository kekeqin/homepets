class PetHistoryEntry {
  const PetHistoryEntry({
    required this.title,
    required this.points,
    required this.eventType,
    this.description,
    this.createdAt,
  });

  factory PetHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['task_title'] ?? json['title'] ?? '').toString();
    final eventType = (json['event_type'] ?? 'task').toString();

    return PetHistoryEntry(
      title: rawTitle.trim().isEmpty ? _defaultTitleFor(eventType) : rawTitle,
      points: _toInt(json['points']) ?? 0,
      eventType: eventType,
      description: (json['description'] as String?)?.trim(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  final String title;
  final int points;
  final String eventType;
  final String? description;
  final DateTime? createdAt;

  bool get isPositive => points >= 0;

  String get subtitle {
    final desc = description;
    if (desc != null && desc.isNotEmpty) {
      return desc;
    }
    return switch (eventType) {
      'feed' => '喂养记录',
      'hatch' => '孵化记录',
      'task' => '任务成长',
      _ => '成长记录',
    };
  }

  static String _defaultTitleFor(String eventType) {
    return switch (eventType) {
      'feed' => '喂养完成',
      'hatch' => '孵化成功',
      'task' => '完成任务',
      _ => '成长记录',
    };
  }
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
