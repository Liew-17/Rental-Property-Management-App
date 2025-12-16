import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/property_management_card.dart';
import 'package:flutter_application/models/property.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/add_property_page.dart';
import 'package:flutter_application/pages/property_management_page.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';

class MyPropertyPage extends StatefulWidget {
  const MyPropertyPage({super.key});

  @override
  State<MyPropertyPage> createState() => _MyPropertyPageState();
}

class _MyPropertyPageState extends State<MyPropertyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State variables
  List<Property> _ownedProperties = [];
  List<Property> _rentedProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProperties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch both owned and rented properties
  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AppUser().id ?? 0;
      
      // Fetch both lists in parallel
      final results = await Future.wait([
        PropertyService.getOwnedProperties(userId),
        PropertyService.getRentedProperties(userId),
      ]);

      if (mounted) {
        setState(() {
          _ownedProperties = results[0];
          _rentedProperties = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading properties: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        title: const Text(
          'My Properties',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Owned'),
            Tab(text: 'Rented'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddPropertyPage()),
          );

          if (result == true) {
            _loadProperties(); // Refresh list after adding
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Owned Properties
                _ownedProperties.isEmpty
                    ? _buildEmptyState('No owned properties yet.', Icons.home_work_outlined)
                    : RefreshIndicator(
                        onRefresh: _loadProperties,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _ownedProperties.length,
                          itemBuilder: (context, i) {
                            final p = _ownedProperties[i];
                            return OwnedPropertyCard(
                              property: p,
                              onView: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyManagementPage(
                                      propertyId: p.id,
                                      mode: PropertyMode.owned,
                                    ),
                                  ),
                                ).then((_) => _loadProperties());
                              },
                              onDelete: () {
                                // TODO: Implement delete logic
                              },
                            );
                          },
                        ),
                      ),

                // Tab 2: Rented Properties
                _rentedProperties.isEmpty
                    ? _buildEmptyState('No rented properties yet.', Icons.vpn_key_outlined)
                    : RefreshIndicator(
                        onRefresh: _loadProperties,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rentedProperties.length,
                          itemBuilder: (context, i) {
                            final p = _rentedProperties[i];
                            return RentedPropertyCard(
                              property: p,
                              onView: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyManagementPage(
                                      propertyId: p.id,
                                      mode: PropertyMode.rented,
                                    ),
                                  ),
                                ).then((_) => _loadProperties());
                              },
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}