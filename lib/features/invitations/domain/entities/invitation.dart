enum InvitationStatus { pending, accepted, expired, cancelled }

class Invitation {
  final String id;
  final String homeId;
  final String? email;
  final String? phone;
  final String role;
  final String token;
  final InvitationStatus status;
  final String invitedBy;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? createdAt;

  const Invitation({
    required this.id,
    required this.homeId,
    this.email,
    this.phone,
    required this.role,
    required this.token,
    required this.status,
    required this.invitedBy,
    this.expiresAt,
    this.acceptedAt,
    this.createdAt,
  });

  bool get isPending => status == InvitationStatus.pending;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  Invitation copyWith({
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
    return Invitation(
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
