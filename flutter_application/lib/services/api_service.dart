import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  
  static String _baseUrl = "http://192.168.0.19:5000";

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

static Future<void> updateBaseUrl(String newIp) async {
    final prefs = await SharedPreferences.getInstance();
    
    String finalUrl = newIp.startsWith("http") ? newIp : "http://$newIp:5000";
    
    _baseUrl = finalUrl;
    
    await prefs.setString('api_url', finalUrl);
  }

  static Future<void> loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_url') ?? _baseUrl;
  }

}