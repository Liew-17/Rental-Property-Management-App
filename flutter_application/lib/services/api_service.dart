class ApiService {
  static const String _baseUrl = "http://127.0.0.1:5000"; // modify this to backend address

  static Uri buildUri(String endpoint) {
    return Uri.parse("$_baseUrl$endpoint");
  }
}