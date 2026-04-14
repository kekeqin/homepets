import '../../../models/pet.dart';

class MemberTaskCompletion {
  const MemberTaskCompletion({
    required this.taskId,
    required this.taskTitle,
    required this.taskPoints,
    required this.taskType,
    required this.createdAt,
  });

  factory MemberTaskCompletion.fromJson(Map<String, dynamic> json) {
    return MemberTaskCompletion(
      taskId: _toInt(json['task_id']) ?? 0,
      taskTitle: (json['task_title'] ?? '任务').toString(),
      taskPoints: _toInt(json['task_points']) ?? 0,
      taskType: (json['task_type'] ?? 'daily').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  final int taskId;
  final String taskTitle;
  final int taskPoints;
  final String taskType;
  final DateTime? createdAt;
}

class MemberProfileViewData {
  const MemberProfileViewData({
    this.pets = const <Pet>[],
    this.completions = const <MemberTaskCompletion>[],
    this.memberPoints = 0,
    this.avatarUrl,
  });

  static const empty = MemberProfileViewData();

  final List<Pet> pets;
  final List<MemberTaskCompletion> completions;
  final int memberPoints;
  final String? avatarUrl;
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
