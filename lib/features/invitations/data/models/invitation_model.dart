import '../../domain/entities/invitation.dart';

class InvitationModel extends Invitation {
  const InvitationModel({
    required super.id,
    required super.homeId,
    super.email,
    super.phone,
    required super.role,
    required super.token,
    required super.status,
    required super.invitedBy,
    super.expiresAt,
    super.acceptedAt,
    super.createdAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'member',
      token: json['token'] as String,
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      invitedBy: json['invited_by'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
      'status': status.name,
      'invited_by': invitedBy,
      'expires_at': expiresAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static InvitationStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'expired':
        return InvitationStatus.expired;
      case 'cancelled':
        return InvitationStatus.cancelled;
      default:
        return InvitationStatus.pending;
    }
  }

  InvitationModel copyWithModel({
    String? id,
    String? homeId,
    String? email,
    String? phone,
    String? role,
    String? token,
    InvitationStatus? status,
    String? invitedBy,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? createdAt,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      token: token ?? this.token,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
