import 'dart:convert';
import 'dart:ffi';

import 'package:gathermap/controllers/utils/configs.dart';
import 'package:gathermap/controllers/utils/database_connector.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/controllers/utils/type_request.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// void main() {
//   RequestAuth.login("","");
//   RequestAuth.isJwtValid();
// }

class RequestAuth {
  static Future<String?> login(String email, String password) async {
    return "Skip";
    // try {
    //   final Session res = await DatabaseConnector.getClient().auth.signInWithPassword(
    //     email: email,
    //     password: password,
    //   );

    //   final String jwt = res.accessToken;
    //   final String? refresh = res.refreshToken;
    //   return jwt;
    // } on AuthException catch (e) {
    //   print('Erreur d\'authentification : ${e.message}');
    //   return null;
    // }
  }

  static Future<bool> isJwtValid() async {
    // final Session? session = DatabaseConnector.getClient().auth.currentSession;

    // //Test remaining time client
    // if (session == null) {
    //   print('Pas de session');
    //   return false;
    // } else if (session.isExpired) {
    //   print('Token expiré');
    //   return false;
    // }

    // //Test token valid server
    // try {
    //   await DatabaseConnector.getClient().auth.getUser();
    // } on AuthException catch (e) {
    //   print('Token invalide ou révoqué : ${e.message}');
    //   return false;
    // }

    // print('Token valide jusqu\'à ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt!.millisecond * 1000)}');
    return true;
  }
}