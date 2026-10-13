class HTTPContainer {
  final int _statusCode;
  final String _message;
  final Map<String,dynamic>? _data;

  HTTPContainer._(this._statusCode, this._message, [this._data = const <String, dynamic>{}]);

  static HTTPContainer getInstance(int code, [Map<String,dynamic>? data = const <String, dynamic>{}]) {
    String message = "";
    switch(code){
      case 200: message = "OK";
      case 201: message = "Created";
      case 204: message = "No Content";
      case 401: message = "Not Authorized";
      case 403: message = "Forbidden";
      case 404: message = "Not Found";
      case 405: message = "Method Not Allowed";
      case 500: message = "Internal Server Error";
      default: 'Erreur Non Connue';
    }
    return HTTPContainer._(code, message, data);
  }

  int getCode(){
    return _statusCode;
  }

  String getMessage(){
    return _message;
  }

  Map<String, dynamic>? getData(){
    return _data;
  }
}