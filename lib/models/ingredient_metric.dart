class IngredientMetric {
  final int id;
  final String name;
  final String description;
  final String function;
  final String riskLevel;
  final int usageCount;
  final DateTime? createdAt;

  IngredientMetric({
    required this.id,
    required this.name,
    required this.description,
    required this.function,
    required this.riskLevel,
    required this.usageCount,
    this.createdAt,
  });

  /// Map JSON to IngredientMetric
  factory IngredientMetric.fromJson(Map<String, dynamic> json) {
    return IngredientMetric(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['ingredient_name'] ?? '',
      description: json['description'] ?? '',
      function: json['function'] ?? '',
      riskLevel: json['risk_level'] ?? '',
      usageCount: json['usage_count'] ?? json['scan_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  /// Convert IngredientMetric to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'function': function,
      'risk_level': riskLevel,
      'usage_count': usageCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
