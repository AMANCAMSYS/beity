class Home {
  final String id;
  final String name;
  final String type;
  final String ownerId;
  final String defaultCurrency;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Home({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    this.defaultCurrency = 'TRY',
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Home.fromJson(Map<String, dynamic> json) {
    return Home(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      ownerId: json['owner_id'] as String,
      defaultCurrency: json['default_currency'] as String? ?? 'TRY',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'owner_id': ownerId,
      'default_currency': defaultCurrency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
