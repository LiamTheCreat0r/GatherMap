import 'package:supabase_flutter/supabase_flutter.dart';

/// Single point of access to the Supabase client for the controller layer.
///
/// Controllers receive an instance through their constructor so a test can
/// inject a client pointing anywhere. The default resolves
/// [Supabase.instance.client] lazily, which keeps construction free of side
/// effects: nothing touches Supabase until a query actually runs.
class SupabaseService {
  SupabaseService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  /// The client used for every query. Falls back to the global instance
  /// created by `Supabase.initialize` in `main.dart`.
  SupabaseClient get client => _client ?? Supabase.instance.client;
}
