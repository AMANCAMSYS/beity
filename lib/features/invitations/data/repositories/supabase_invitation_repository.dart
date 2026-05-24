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

    try {
      // Use server-side RPC for secure token generation and validation
      final response = await _client.rpc(
        'create_invitation',
        params: {
          'p_home_id': homeId,
          'p_email': email,
          'p_role': role,
        },
      );

      return InvitationModel.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // Map server errors to user-friendly messages
      if (e.message.contains('already an active member')) {
        throw Exception('هذا المستخدم عضو بالفعل في المنزل');
      }
      if (e.message.contains('pending invitation already exists')) {
        throw Exception('يوجد دعوة معلقة بالفعل لهذا البريد الإلكتروني');
      }
      if (e.message.contains('Only owners and admins')) {
        throw Exception('ليس لديك صلاحية لإرسال دعوات');
      }
      if (e.message.contains('gen_random_bytes')) {
        throw Exception('تعذر إنشاء رمز الدعوة. يرجى تحديث قاعدة البيانات ثم المحاولة مرة أخرى');
      }
      throw Exception('فشل إرسال الدعوة: ${e.message}');
    }
  }

  @override
  Future<InvitationModel> acceptInvitation({required String token}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    try {
      final response = await _client.rpc(
        'accept_invitation',
        params: {'invitation_token': token},
      );
      return InvitationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('Not authenticated')) {
        throw Exception('يجب تسجيل الدخول أولاً');
      } else if (e.toString().contains('Invitation not found')) {
        throw Exception('الدعوة غير موجودة أو تم التعامل معها مسبقاً');
      } else if (e.toString().contains('Invitation expired')) {
        throw Exception('الدعوة منتهية الصلاحية');
      } else if (e.toString().contains('Unauthorized')) {
        throw Exception('غير مصرح لك بقبول هذه الدعوة');
      }
      throw Exception('فشل في قبول الدعوة: $e');
    }
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
        .maybeSingle();

    if (invitation == null) {
      throw Exception('الدعوة غير موجودة');
    }

    final response = await _client
        .from('invitations')
        .update({'status': 'cancelled'})
        .eq('id', invitation['id'])
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('ليس لديك صلاحية لرفض هذه الدعوة');
    }

    return InvitationModel.fromJson(response);
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
        .maybeSingle();

    if (invitation == null) {
      throw Exception('الدعوة غير موجودة');
    }

    final response = await _client
        .from('invitations')
        .update({'status': 'cancelled'})
        .eq('id', invitationId)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('ليس لديك صلاحية لإلغاء هذه الدعوة');
    }

    return InvitationModel.fromJson(response);
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
            .where((inv) => inv.isPending)
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

}
