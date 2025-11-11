import 'package:flutter/material.dart';
import 'package:flutter_application/theme.dart'; 

class MyPropertyPage extends StatefulWidget {
  const MyPropertyPage({super.key});

  @override
  State<MyPropertyPage> createState() => _MyPropertyPageState();
}

class _MyPropertyPageState extends State<MyPropertyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          debugPrint("Add new property tapped!"); //To Add Property Page
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor, 
        centerTitle: true,                      
        title: const Text(
          'My Properties',
          style: TextStyle(
            color: Colors.white,                
            fontWeight: FontWeight.bold,        
          ),
        ),
      ),

      body: Column(
        children: [
          TabBar(
            controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Owned'),
              Tab(text: 'Rented'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Owned Properties
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          'No owned properties yet.', 
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),

                // Rented Properties 
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          'No rented properties yet.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}