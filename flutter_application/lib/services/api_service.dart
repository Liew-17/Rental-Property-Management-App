class ApiService {
  static const String _baseUrl = "http://192.168.0.19:5000";

  static String getApiAddress() => _baseUrl;

  static Uri buildUri(String endpoint) {
    if (!endpoint.startsWith("/")){
      endpoint = "/$endpoint";
    }
    return Uri.parse("$_baseUrl$endpoint");
  }

  static String buildFileUrl(String filePath, {bool download = false}) {
    if (!filePath.startsWith("/")) { 
      filePath = "/$filePath";
    }

    String url = "$_baseUrl$filePath";

    if (download) {
      // Check if URL already has query parameters
      if (url.contains("?")) {
        url += "&download=true";
      } else {
        url += "?download=true";
      }
    }

    return url;
  }


  static String buildImageUrl(String filePath) => buildFileUrl(filePath);

}