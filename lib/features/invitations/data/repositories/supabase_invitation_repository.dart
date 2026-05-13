import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation_model.dart';
import 'invitation_repository.dart';

class SupabaseInvitationRepository implements InvitationRepository {
  final SupabaseClient _client;

  SupabaseInvitationRepository(this._client);

  @override
  Future<InvitationModel> sendInvitation({
    required String homeId,
    required String email,
    required String role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check if user is owner/admin of the home
    final membership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', user.id)
        .single();

    if (membership == null ||
        (membership['role'] != 'owner' && membership['role'] != 'admin')) {
      throw Exception('ليس لديك صلاحية لإرسال دعوات');
    }

    // Check if email is already a member
    final existingMember = await _client
        .from('home_members')
        .select('id')
        .eq('home_id', homeId)
        .eq('user_id', _client.auth.currentUser!.id)
        .maybeSingle();

    // Check for existing pending invitation
    final existingInvitation = await _client
        .from('invitations')
        .select('id')
        .eq('home_id', homeId)
        .eq('email', email)
        .eq('status', 'pending')
        .maybeSingle();

    if (existingInvitation != null) {
      throw Exception('يوجد دعوة معلقة بالفعل لهذا البريد الإلكتروني');
    }

    // Generate unique token
    final token = _generateToken();

    // Create invitation
    final response = await _client
        .from('invitations')
        .insert({
          'home_id': homeId,
          'email': email,
          'role': role,
          'token': token,
          'status': 'pending',
          'invited_by': user.id,
          'expires_at':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        })
        .select()
        .single();

    return InvitationModel.fromJson(response);
  }

  @override
  Future<InvitationModel> acceptInvitation({required String token}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Get invitation by token
    final invitation = await _client
        .from('invitations')
        .select()
        .eq('token', token)
        .eq('status', 'pending')
        .single();

    if (invitation == null) {
      throw Exception('الدعوة غير موجودة أو منتهية الصلاحية');
    }

    // Check if expired
    final expiresAt = DateTime.parse(invitation['expires_at']);
    if (expiresAt.isBefore(DateTime.now())) {
      // Mark as expired
      await _client
          .from('invitations')
          .update({'status': 'expired'}).eq('id', invitation['id']);
      throw Exception('الدعوة منتهية الصلاحية');
    }

    // Update invitation status
    await _client.from('invitations').update({
      'status': 'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', invitation['id']);

    // Add user to home_members
    await _client.from('home_members').insert({
      'home_id': invitation['home_id'],
      'user_id': user.id,
      'role': invitation['role'],
      'status': 'active',
    });

    // Log activity
    await _client.from('activity_logs').insert({
      'home_id': invitation['home_id'],
      'user_id': user.id,
      'action': 'invitation_accepted',
      'entity_type': 'invitation',
      'entity_id': invitation['id'],
    });

    return InvitationModel.fromJson(
        {...invitation, 'status': 'accepted', 'accepted_at': DateTime.now().toIso8601String()});
  }

  @override
  Future<InvitationModel> declineInvitation({required String token}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final invitation = await _client
        .from('invitations')
        .select()
        .eq('token', token)
        .eq('status', 'pending')
        .single();

    if (invitation == null) {
      throw Exception('الدعوة غير موجودة');
    }

    await _client
        .from('invitations')
        .update({'status': 'cancelled'}).eq('id', invitation['id']);

    return InvitationModel.fromJson({...invitation, 'status': 'cancelled'});
  }

  @override
  Future<InvitationModel> cancelInvitation(
      {required String invitationId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final invitation = await _client
        .from('invitations')
        .select()
        .eq('id', invitationId)
        .single();

    if (invitation == null) {
      throw Exception('الدعوة غير موجودة');
    }

    await _client
        .from('invitations')
        .update({'status': 'cancelled'}).eq('id', invitationId);

    return InvitationModel.fromJson({...invitation, 'status': 'cancelled'});
  }

  @override
  Future<List<InvitationModel>> getHomeInvitations(
      {required String homeId}) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('home_id', homeId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InvitationModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<InvitationModel>> getUserInvitations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('invitations')
        .select()
        .eq('email', user.email!)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InvitationModel.fromJson(json))
        .toList();
  }

  @override
  Future<InvitationModel?> getInvitationByToken(
      {required String token}) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('token', token)
        .maybeSingle();

    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }

  @override
  Stream<List<InvitationModel>> watchHomeInvitations(
      {required String homeId}) {
    return _client
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('created_at', ascending: false)
        .map((response) => response
            .map((json) => InvitationModel.fromJson(json))
            .toList());
  }

  @override
  Stream<List<InvitationModel>> watchUserInvitations() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _client
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('email', user.email!)
        .order('created_at', ascending: false)
        .map((response) => response
            .map((json) => InvitationModel.fromJson(json))
            .where((inv) => inv.isPending)
            .toList());
  }

  String _generateToken() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }
}
