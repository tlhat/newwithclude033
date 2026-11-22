import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class SupabaseCloudSyncResult {
  final bool success;
  final int syncedMutationsCount;
  final bool rlsDenied;
  final String message;
  final List<String> appliedKeys;

  const SupabaseCloudSyncResult({
    required this.success,
    this.syncedMutationsCount = 0,
    this.rlsDenied = false,
    this.message = '',
    this.appliedKeys = const [],
  });
}

class SupabaseRemoteDataSource {
  /// Injectable HTTP client for deterministic unit testing of Supabase REST, RPC,
  /// RLS policies, and Edge Functions.
  static http.Client? httpClientOverride;

  final SupabaseEnvConfig config;

  SupabaseRemoteDataSource(this.config);

  Map<String, String> _buildAuthHeaders(String sessionAccessToken) {
    final String cleanBearer = sessionAccessToken.trim();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (config.supabaseAnonKey.trim().isNotEmpty)
        'apikey': config.supabaseAnonKey.trim(),
      if (cleanBearer.isNotEmpty) 'Authorization': 'Bearer $cleanBearer',
      'Prefer': 'return=representation,resolution=merge-duplicates',
    };
  }

  bool get canConnectToSupabase =>
      config.isConfigured &&
      AppNetworkPolicyGuard.canPerformOutboundNetworkRequest();

  /// Sends a batch of queued offline mutations to the Supabase `sync-batch` Edge Function
  /// (or `/rest/v1/rpc/rpc_apply_sync_batch`), enforcing `Authorization: Bearer <token>`
  /// and idempotency keys.
  Future<SupabaseCloudSyncResult> flushMutationBatch({
    required String sessionAccessToken,
    required String authenticatedParentEmail,
    required List<SyncMutationRecord> batch,
  }) async {
    if (batch.isEmpty) {
      return const SupabaseCloudSyncResult(
        success: true,
        syncedMutationsCount: 0,
        message: 'لا توجد تغييرات معلقة للمزامنة.',
      );
    }
    if (!canConnectToSupabase) {
      return const SupabaseCloudSyncResult(
        success: false,
        syncedMutationsCount: 0,
        message: 'وضع عدم الاتصال مفعّل أو لم يتم ضبط رابط Supabase؛ تم حفظ التغييرات محلياً في طابور المزامنة.',
      );
    }
    if (sessionAccessToken.trim().isEmpty) {
      return const SupabaseCloudSyncResult(
        success: false,
        rlsDenied: true,
        message: 'رفض RLS: لا يوجد رمز جلسة (Bearer Access Token) صالح للمزامنة.',
      );
    }

    final String normAuthEmail = authenticatedParentEmail.trim().toLowerCase();
    for (final m in batch) {
      if (m.parentEmail.trim().toLowerCase() != normAuthEmail) {
        return const SupabaseCloudSyncResult(
          success: false,
          rlsDenied: true,
          message: 'رفض RLS (IDOR Protection): لا يُسمح بمزامنة بيانات تخص حساب ولي أمر آخر.',
        );
      }
    }

    final http.Client client = httpClientOverride ?? http.Client();
    final bool shouldClose = httpClientOverride == null;
    try {
      final response = await client
          .post(
            config.edgeFunctionUri('sync-batch'),
            headers: _buildAuthHeaders(sessionAccessToken),
            body: jsonEncode({
              'authenticatedEmail': normAuthEmail,
              'mutations': batch.map((m) => m.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const SupabaseCloudSyncResult(
          success: false,
          rlsDenied: true,
          message: 'رفض سياسات أمان الصفوف (Supabase RLS): غير مصرح بالوصول.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<String> applied = (decoded is Map && decoded['appliedKeys'] is List)
            ? (decoded['appliedKeys'] as List).map((e) => e.toString().trim()).where((k) => k.isNotEmpty).toList()
            : <String>[];
        return SupabaseCloudSyncResult(
          success: applied.isNotEmpty,
          syncedMutationsCount: applied.length,
          appliedKeys: applied,
          message: applied.isNotEmpty
              ? 'تمت مزامنة ${applied.length} عملية سحابياً مع Supabase بنجاح.'
              : 'لم يتم تطبيق أي عمليات جديدة على الخادم السحابي.',
        );
      }
      return SupabaseCloudSyncResult(
        success: false,
        message: 'تعذر إتمام المزامنة السحابية (كود: ${response.statusCode}).',
      );
    } catch (_) {
      return const SupabaseCloudSyncResult(
        success: false,
        message: 'انقطع الاتصال أثناء المزامنة؛ ستتم إعادة المحاولة تلقائياً عند عودة الإنترنت.',
      );
    } finally {
      if (shouldClose) client.close();
    }
  }

  /// Fetches the parent's child profiles from `GET /rest/v1/child_profiles`,
  /// verifying that every returned row belongs to the authenticated parent (RLS check).
  Future<List<ChildProfile>?> fetchRemoteChildProfiles({
    required String sessionAccessToken,
    required String expectedParentEmail,
  }) async {
    if (!canConnectToSupabase || sessionAccessToken.trim().isEmpty) {
      return null;
    }
    final http.Client client = httpClientOverride ?? http.Client();
    final bool shouldClose = httpClientOverride == null;
    try {
      final response = await client
          .get(
            config.restTableUri('child_profiles', {'select': '*'}),
            headers: _buildAuthHeaders(sessionAccessToken),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 401 || response.statusCode == 403) {
        return null;
      }
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final List<ChildProfile> result = [];
          for (final item in decoded) {
            if (item is Map) {
              final String ownerEmail =
                  (item['parentEmail'] ?? expectedParentEmail)
                      .toString()
                      .trim()
                      .toLowerCase();
              if (ownerEmail != expectedParentEmail.trim().toLowerCase()) {
                // Client-side defense-in-depth if a misconfigured mock returned another user's row
                continue;
              }
              result.add(
                  ChildProfile.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          return result;
        }
      }
    } catch (_) {
    } finally {
      if (shouldClose) client.close();
    }
    return null;
  }

  /// Calls a server-side PostgreSQL RPC (`rpc_clear_child_activity_history_only`,
  /// `rpc_delete_all_child_data`, or `rpc_delete_parent_account_cascade`).
  Future<bool> invokeServerRpc({
    required String rpcName,
    required String sessionAccessToken,
    Map<String, dynamic> params = const {},
  }) async {
    if (!canConnectToSupabase || sessionAccessToken.trim().isEmpty) {
      return false;
    }
    final http.Client client = httpClientOverride ?? http.Client();
    final bool shouldClose = httpClientOverride == null;
    try {
      final response = await client
          .post(
            config.rpcUri(rpcName),
            headers: _buildAuthHeaders(sessionAccessToken),
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    } finally {
      if (shouldClose) client.close();
    }
  }
}
