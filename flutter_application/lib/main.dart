import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application/pages/login_page.dart';
import 'package:flutter_application/pages/search_page.dart';
import 'package:flutter_application/services/api_service.dart'; 
import 'firebase_options.dart'; 
import 'pages/profile_page.dart';
import 'pages/register_page.dart';
import 'pages/main_page.dart';
import 'pages/add_property_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ApiService.loadUrl();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => const MainPage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/register': (context) => const RegisterPage(),
        '/search': (context) => const SearchPage(),
        '/add': (context) => const AddPropertyPage()
        
      },
      debugShowCheckedModeBanner: false,
    );
  }
}



