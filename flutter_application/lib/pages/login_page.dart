import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:http/http.dart' as http;
import 'package:flutter_application/services/api_service.dart';
import 'dart:convert';
import 'package:flutter_application/models/user.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {

    final providers = [EmailAuthProvider()];


    void onSignedIn() {
      Navigator.pushReplacementNamed(context, '/');
    }

    void onRegister(){
      Navigator.pushReplacementNamed(context, '/register');
    }

    Future<void> handleAuthState(BuildContext context, User user) async {

      try {
          final url = ApiService.buildUri('/auth/check/${user.uid}');
          final response = await http.get(url);

          final data = jsonDecode(response.body);
    
          bool exists = data['exists'] ?? false;


          if (exists) {
            AppUser appUser = AppUser();
            final userData = data['user'];
              appUser.id = userData['id'];
              appUser.name = userData['name'];
              appUser.state = userData['state'];
              appUser.city = userData['city'];
              appUser.district = userData['district'];

          
            onSignedIn();     
          } else {
            onRegister();
          }

        } catch (e) {
          debugPrint('Error checking user: $e');
        }
    }

    return SignInScreen(
      providers: providers,
      actions: [
        AuthStateChangeAction<UserCreated>((context, state) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            handleAuthState(context, user);
          }
        }),
        AuthStateChangeAction<SignedIn>((context, state) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            handleAuthState(context, user);
          }
        }),
      ],
    );
  }
}