class ApiService {
  static const String _baseUrl = "http://192.168.0.13:5000"; // backend address

  static Uri buildUri(String endpoint) {
    return Uri.parse("$_baseUrl$endpoint");
  }

  static String buildImageUrl(String filePath) {
  if (!filePath.startsWith("/")) { 
    filePath = "/$filePath"; // ensure path start with '/'
  }

  return "$_baseUrl$filePath";
  }

}