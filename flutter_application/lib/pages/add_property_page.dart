import 'package:flutter/material.dart';


class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPage();
}

class _AddPropertyPage extends State<AddPropertyPage> {



   @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome! You are logged in."),
            const SizedBox(height: 20),          
          ],
        ),
      ),
    );
  }

}