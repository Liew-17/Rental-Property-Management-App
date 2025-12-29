import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter_application/pages/main_page.dart';
import 'package:flutter_application/pages/register_page.dart';
import 'package:flutter_application/services/socket_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application/services/api_service.dart';
import 'dart:convert';
import 'package:flutter_application/models/user.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    // --- Helper Methods for Navigation ---
    void onSignedIn() {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
      );
    }

    void onRegister() {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        ),
        (route) => false,
      );
    }

    // --- API Configuration Dialog ---
    void showApiDialog(BuildContext context) {
      // Create a controller with the current URL pre-filled
      final TextEditingController ipController = TextEditingController(
        text: (ApiService.getApiAddress())
        .replaceAll("http://", "")
        .replaceAll(":5000", "")
      );

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Configure Server IP"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter your laptop's IP Address:"),
                const SizedBox(height: 10),
                TextField(
                  controller: ipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "e.g. 192.168.0.105",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ApiService.updateBaseUrl(ipController.text); 
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("API connected to: ${ApiService.getApiAddress()}")),
                    );
                  }
                },
                child: const Text("Save"),
              )
            ],
          );
        },
      );
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
          appUser.name = userData['username'];
          appUser.state = userData['state'];
          appUser.city = userData['city'];
          appUser.district = userData['district'];
          appUser.email = userData['email'];
          appUser.profilePicUrl = userData['profilePicUrl'];
          appUser.role = userData['role'] ?? 'tenant';

          if (appUser.id != null) {
            SocketService.connect(appUser.id!);
          }

          onSignedIn();
        } else {
          onRegister();
        }
      } catch (e) {
        debugPrint('Error checking user: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection Error: $e'), 
              action: SnackBarAction(label: "Settings", onPressed: () => showApiDialog(context)),
            )
          );
        }
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      child: SignInScreen(
        providers: providers,
   
        headerBuilder: (context, constraints, shrinkOffset) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_work_rounded, // House icon
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "MyRental",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.grey),
                    tooltip: "Change Server IP",
                    onPressed: () => showApiDialog(context),
                  ),
                ),
              ],
            ),
          );
        },
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
      ),
    );
  }
}