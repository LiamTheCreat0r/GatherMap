import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment{
  static final String _url = dotenv.env['SUPABASE_URL']!;
  static final String _api = dotenv.env['SUPABASE_PUBLISHABLE_KEY']!;

  static String getUrl(){
    return _url;
  }

  static String getServApi(){
    return _api;
  }
}