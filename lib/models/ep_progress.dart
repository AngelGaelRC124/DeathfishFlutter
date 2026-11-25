class EpProgress {
  const EpProgress({
    required this.projectName,
    required this.stage,
    required this.percentage,
    required this.statusNote,
  });

  final String projectName;
  final String stage;
  final int percentage;
  final String statusNote;

  factory EpProgress.fromJson(Map<String, dynamic> json) => EpProgress(
    projectName: json['projectName'] as String? ?? '',
    stage: json['stage'] as String? ?? '',
    percentage: (json['percentage'] as num? ?? 0).clamp(0, 100).toInt(),
    statusNote: json['statusNote'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'projectName': projectName,
    'stage': stage,
    'percentage': percentage.clamp(0, 100),
    'statusNote': statusNote,
  };
}
