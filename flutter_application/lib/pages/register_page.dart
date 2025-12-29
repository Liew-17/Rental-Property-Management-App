import 'package:flutter/material.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/main_page.dart';
import 'package:flutter_application/services/socket_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application/services/api_service.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isButtonEnabled = false;

  void _onUsernameChanged() {
    setState(() {
      _isButtonEnabled = _usernameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _registerUser() async {
    final user = FirebaseAuth.instance.currentUser; // get current login user

    if (user == null) {    
      return;
    }

    final uid = user.uid;
    final username = _usernameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final url = ApiService.buildUri("/auth/register");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'username': username,
          'role': 'user', 
          'email': user.email
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        
        AppUser appUser = AppUser();
        appUser.id =  data['id'];
        appUser.name = data['username'];
        appUser.email = data['email'];
        appUser.role = 'tenant';

        if (appUser.id != null) {
          SocketService.connect(appUser.id!);
        }
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        );
      }

    } catch (e) {
       debugPrint('Failed to register user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      }); 
    }


  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register"),
      foregroundColor: Colors.white,
      backgroundColor: AppTheme.primaryColor,
      centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter your username:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isButtonEnabled && !_isLoading ? _registerUser : null,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }
}