import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/property_management_card.dart';
import 'package:flutter_application/models/property.dart';
import 'package:flutter_application/pages/property_management_page.dart';
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

  Future<List<Property>> loadOwnedProperties() async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate network
    return [
      Property(
        id: 1,
        name: "Condo KL",
        title: "High Floor City View",
        type: "residence",
        status: "listed",
        thumbnailUrl: "",
      ),
      Property(
        id: 2,
        name: "Landed House",
        title: "Double Storey Bandar Setia",
        type: "residence",
        status: "rented",
        thumbnailUrl: "",
      ),
    ];
  }

  Future<List<Property>> loadRentedProperties() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Property(
        id: 10,
        name: "Room Rental",
        title: "Master Bedroom Setapak",
        type: "residence",
        status: "active",
        thumbnailUrl: "",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        title: const Text(
          'My Properties',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                // Owned Properties Tab
                FutureBuilder<List<Property>>(
                  future: loadOwnedProperties(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final properties = snapshot.data!;
                    if (properties.isEmpty) {
                      return const Center(
                        child: Text(
                          'No owned properties yet.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: properties.length,
                      itemBuilder: (context, i) {
                        final p = properties[i];
                        return OwnedPropertyCard(
                          property: p,
                          onView: () {
                            // Navigate to OwnerPropertyManagementPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyManagementPage(
                                  property: p,
                                  mode: PropertyMode.owned,
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            // TODO: delete
                          },
                        );
                      },
                    );
                  },
                ),

                // Rented Properties Tab
                FutureBuilder<List<Property>>(
                  future: loadRentedProperties(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final properties = snapshot.data!;
                    if (properties.isEmpty) {
                      return const Center(
                        child: Text(
                          'No rented properties yet.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: properties.length,
                      itemBuilder: (context, i) {
                        final p = properties[i];
                        return RentedPropertyCard(
                          property: p,
                          onView: () {
                            // Navigate to RentedPropertyManagementPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyManagementPage(
                                  property: p,
                                  mode: PropertyMode.rented,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
