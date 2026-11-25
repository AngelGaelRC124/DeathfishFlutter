class SecretCode {
  const SecretCode({
    required this.code,
    required this.rewardTitle,
    required this.rewardDescription,
    required this.active,
    this.secretUrl,
  });

  final String code;
  final String rewardTitle;
  final String rewardDescription;
  final bool active;
  final String? secretUrl;

  factory SecretCode.fromJson(Map<String, dynamic> json) => SecretCode(
    code: json['code'] as String,
    rewardTitle: json['rewardTitle'] as String? ?? '',
    rewardDescription: json['rewardDescription'] as String? ?? '',
    active: json['active'] as bool? ?? false,
    secretUrl: json['secretUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'rewardTitle': rewardTitle,
    'rewardDescription': rewardDescription,
    'secretUrl': secretUrl,
    'active': active,
  };
}
