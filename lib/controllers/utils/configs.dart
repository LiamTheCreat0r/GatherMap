class Configs{

  static const String _servUrl = "http://10.200.146.131:54321/rest/v1";
  static final String _apiKei = "";

  static String getApiKey(){
    return _apiKei;
  }

  static String getServUrl(){
    return _servUrl;
  }

  static String getAuthUrl(){
    return _servUrl;
  }
}