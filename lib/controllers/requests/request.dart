import 'dart:convert';

import 'package:gathermap/controllers/requests/request_auth.dart';
import 'package:gathermap/controllers/utils/configs.dart';
import 'package:gathermap/controllers/utils/database_connector.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/controllers/utils/type_request.dart';
import 'package:gathermap/models/event.dart';
import 'package:http/http.dart' as http;

class Request {

  /// Méthode privée principale pour centraliser les appels cURL
  static Future<HTTPContainer> _requete(
      TypeRequete typeRequete,
      TypeObject typeObjet, {
        BigInt? id,
        Map<String, dynamic>? body,
      }) async {
    await RequestAuth.login("email@gougou.com", "mot2passe");
    if(!(await RequestAuth.isJwtValid())){
      return HTTPContainer.getInstance(401);
    }

    try {
      //NEED THE SERVER URL
      String urlString = "${Configs.getServUrl()}${typeObjet.getUri()}";
      if (id != null) {
        urlString += "?id=eq.$id";
      }
      Uri url = Uri.parse(urlString);
      print("URL $typeRequete ${url.toString()}");

    //NEED THE JWT
      Map<String, String> headers = {
        'apikey':Configs.getApiKey(),
        'Content-Type': 'application/json'
      };

      http.Response response;
      String? jsonBody = body != null ? jsonEncode(body) : null;
      print("jsonBody $jsonBody");

      switch (typeRequete) {
        case TypeRequete.GET:
          response = await http.get(url, headers: headers);
          print("Response ${response.body}");
          break;
        case TypeRequete.POST:
          response = await http.post(url, headers: headers, body: jsonBody);
          break;
        case TypeRequete.DELETE:
          response = await http.delete(url, headers: headers);
          break;
        case TypeRequete.PUT:
          response = await http.put(url, headers: headers, body: jsonBody);
          break;
        case TypeRequete.PATCH:
          response = await http.patch(url, headers: headers, body: jsonBody);
          break;
      }

      // Checking HTTP code (200-299)
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return HTTPContainer.getInstance(response.statusCode);
      }
      //Get return a json when successfull
      if(response.statusCode==200) {
        if (response.body.isEmpty) return HTTPContainer.getInstance(500);
        final List list = jsonDecode(response.body);
        final event = list.isEmpty ? null : list.first as Map<String, dynamic>;
        return HTTPContainer.getInstance(response.statusCode,event);
      }
      return HTTPContainer.getInstance(response.statusCode);
    } catch (e) {
      print("Erreur réseau: $e");
      return HTTPContainer.getInstance(500);
    }
  }

  // --- Méthodes Publiques ---
  static Future<HTTPContainer> get(TypeObject type, BigInt? id) async {
    return _requete(TypeRequete.GET, type, id:id);
  }

  static Future<HTTPContainer> post(TypeObject type, Map<String, dynamic> body) async {
    return _requete(TypeRequete.POST, type, body: body);
  }

  static Future<HTTPContainer> delete(TypeObject type, BigInt id) async {
    return _requete(TypeRequete.DELETE, type, id: id);
  }

  static Future<HTTPContainer> put(TypeObject type, BigInt id, Map<String, dynamic> body) async {
    return _requete(TypeRequete.PUT, type, id: id, body: body);
  }

  static Future<HTTPContainer> patch(TypeObject type, BigInt id, Map<String, dynamic> body) async {
    return _requete(TypeRequete.PATCH, type, id: id, body: body);
  }
}