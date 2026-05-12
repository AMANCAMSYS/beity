import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/home_member.dart';

part 'home_member_model.g.dart';

@JsonSerializable()
class HomeMemberModel {
  final String id;
  @JsonKey(name: 'home_id')
  final String homeId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String role;
  final String status;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @JsonKey(name: 'user_name')
  final String? userName;
  @JsonKey(name: 'user_email')
  final String? userEmail;

  const HomeMemberModel({
    required this.id,
    required this.homeId,
    required this.userId,
    required this.role,
    this.status = 'active',
    required this.joinedAt,
    this.deletedAt,
    this.userName,
    this.userEmail,
  });

  factory HomeMemberModel.fromJson(Map<String, dynamic> json) =>
      _$HomeMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$HomeMemberModelToJson(this);

  HomeMember toEntity() {
    return HomeMember(
      id: id,
      homeId: homeId,
      userId: userId,
      role: role,
      status: status,
      joinedAt: joinedAt,
      deletedAt: deletedAt,
    );
  }

  factory HomeMemberModel.fromEntity(HomeMember member) {
    return HomeMemberModel(
      id: member.id,
      homeId: member.homeId,
      userId: member.userId,
      role: member.role,
      status: member.status,
      joinedAt: member.joinedAt,
      deletedAt: member.deletedAt,
    );
  }
}
