import 'package:flutter/material.dart';
import 'package:gathermap/controllers/utils/configs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseConnector {
  
  static final supabase = Supabase.instance.client;

  static Future<void> connect() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: Configs.getServUrl(), 
      publishableKey: Configs.getApiKey(),
    );
  }

  static SupabaseClient getClient(){
    return supabase;
  }
}
