class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.name,
    required this.riskScore,
    required this.location,
    this.logoUrl,
    this.sector,
  });

  final String id;
  final String name;
  final double riskScore;
  final String location;
  final String? logoUrl;
  final String? sector;

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      riskScore: (json['risk_score'] ?? json['riskScore'] ?? 0).toDouble(),
      location: (json['location'] ?? '').toString(),
      logoUrl: json['logo_url']?.toString() ?? json['logoUrl']?.toString(),
      sector: json['sector']?.toString(),
    );
  }
}

class SupplierDependency {
  const SupplierDependency({
    required this.supplierId,
    required this.dependentSupplierId,
    required this.weight,
  });

  final String supplierId;
  final String dependentSupplierId;
  final double weight;

  factory SupplierDependency.fromJson(Map<String, dynamic> json) {
    return SupplierDependency(
      supplierId: (json['supplier_id'] ?? json['supplierId'] ?? '').toString(),
      dependentSupplierId:
          (json['dependent_supplier_id'] ?? json['dependentSupplierId'] ?? '')
              .toString(),
      weight: (json['weight'] ?? 0).toDouble(),
    );
  }
}

class SupplierRecommendation {
  const SupplierRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
  });

  final String id;
  final String title;
  final String description;
  final String priority;

  factory SupplierRecommendation.fromJson(Map<String, dynamic> json) {
    return SupplierRecommendation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
    );
  }
}
