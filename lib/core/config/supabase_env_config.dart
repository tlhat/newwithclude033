import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class SupabaseEnvConfig {
  static const String kEnvSupabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String kEnvSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  String supabaseUrl;
  String supabaseAnonKey;

  SupabaseEnvConfig({
    String? supabaseUrl,
    String? supabaseAnonKey,
  })  : supabaseUrl = (supabaseUrl ?? kEnvSupabaseUrl).trim(),
        supabaseAnonKey = (supabaseAnonKey ?? kEnvSupabaseAnonKey).trim();

  bool get isConfigured {
    final String cleanUrl = supabaseUrl.trim().toLowerCase();
    return cleanUrl.startsWith('https://') &&
        !AppNetworkPolicyGuard.isPrivateOrLoopbackHost(
            Uri.tryParse(supabaseUrl.trim())?.host ?? '') &&
        supabaseAnonKey.trim().isNotEmpty;
  }

  String get normalizedBaseUrl {
    String u = supabaseUrl.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Uri restTableUri(String tableName, [Map<String, String>? queryParams]) {
    final Uri base = Uri.parse('$normalizedBaseUrl/rest/v1/$tableName');
    if (queryParams == null || queryParams.isEmpty) return base;
    return base.replace(queryParameters: queryParams);
  }

  Uri rpcUri(String functionName) =>
      Uri.parse('$normalizedBaseUrl/rest/v1/rpc/$functionName');

  Uri edgeFunctionUri(String functionName) =>
      Uri.parse('$normalizedBaseUrl/functions/v1/$functionName');
}
