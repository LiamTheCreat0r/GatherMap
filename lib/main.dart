import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/logging/logs.dart';

/// App entry point: configures logging and Supabase from the compile-time
/// environment, then runs [MyApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logs.init();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const MyApp());
}
