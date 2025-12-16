class AppUser {
  // Singleton instance
  static final AppUser _instance = AppUser._internal();

  AppUser._internal();

  factory AppUser() => _instance;

  // User fields
  int? id;
  String? name;
  String? email;
  String? profilePicUrl;

  // Location fields
  String? state;
  String? city;
  String? district;

  bool get isLoggedIn => id != null;

  // Reset user info
  void reset() {
    id = null;
    name = null;
    email = null;
    profilePicUrl = null; // <--- Reset this field

    // Reset location
    state = null;
    city = null;
    district = null;
  }
}

