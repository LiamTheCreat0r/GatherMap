import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a Supabase failure into a message safe to show in the UI.
///
/// Supabase errors extend [SupabaseException] (the postgrest, auth, storage
/// and functions packages all share that hierarchy); anything else falls back
/// to `toString`.
String describeError(Object error) {
  if (error is SupabaseApiException) {
    return '${error.message} (${error.errorCode ?? 'HTTP ${error.statusCode}'})';
  }
  if (error is SupabaseException) {
    final code = error.errorCode;
    return code == null ? error.message : '${error.message} ($code)';
  }
  if (error is RealtimeSubscribeException) {
    return 'Realtime subscription failed: ${error.status.name}';
  }
  return error.toString();
}
