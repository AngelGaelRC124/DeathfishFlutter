class EmailJsConfig {
  const EmailJsConfig({
    required this.serviceId,
    required this.templateId,
    required this.publicKey,
  });

  final String serviceId;
  final String templateId;
  final String publicKey;

  factory EmailJsConfig.fromJson(Map<String, dynamic> json) {
    return EmailJsConfig(
      serviceId: json['service_id'] as String,
      templateId: json['template_id'] as String,
      publicKey: json['public_key'] as String,
    );
  }
}

class BandInfo {
  const BandInfo({
    required this.name,
    required this.label,
    required this.year,
    required this.backgroundAsset,
    required this.emailJs,
  });

  final String name;
  final String label;
  final int year;
  final String backgroundAsset;
  final EmailJsConfig emailJs;

  factory BandInfo.fromJson(Map<String, dynamic> json) {
    return BandInfo(
      name: json['name'] as String,
      label: json['label'] as String,
      year: json['year'] as int,
      backgroundAsset: json['background_asset'] as String,
      emailJs: EmailJsConfig.fromJson(
        Map<String, dynamic>.from(json['emailjs'] as Map),
      ),
    );
  }
}
