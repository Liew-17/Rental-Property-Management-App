class ApiService {
  static const String _baseUrl = "http://192.168.0.8:5000"; // backend address

  static Uri buildUri(String endpoint) {
    if (!endpoint.startsWith("/")){
      endpoint = "/$endpoint";
    }
    return Uri.parse("$_baseUrl$endpoint");
  }

  static String buildImageUrl(String filePath) {
  if (!filePath.startsWith("/")) { 
    filePath = "/$filePath"; // ensure path start with '/'
  }

  return "$_baseUrl$filePath";
  }

}