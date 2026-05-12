import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/home.dart';

part 'home_model.g.dart';

@JsonSerializable()
class HomeModel {
  final String id;
  final String name;
  final String type;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'default_currency')
  final String? defaultCurrency;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @JsonKey(name: 'member_count')
  final int? memberCount;

  const HomeModel({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    this.defaultCurrency = 'TRY',
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.memberCount,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) =>
      _$HomeModelFromJson(json);

  Map<String, dynamic> toJson() => _$HomeModelToJson(this);

  Home toEntity() {
    return Home(
      id: id,
      name: name,
      type: type,
      ownerId: ownerId,
      defaultCurrency: defaultCurrency ?? 'TRY',
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory HomeModel.fromEntity(Home home) {
    return HomeModel(
      id: home.id,
      name: home.name,
      type: home.type,
      ownerId: home.ownerId,
      defaultCurrency: home.defaultCurrency,
      createdAt: home.createdAt,
      updatedAt: home.updatedAt,
      deletedAt: home.deletedAt,
    );
  }
}
