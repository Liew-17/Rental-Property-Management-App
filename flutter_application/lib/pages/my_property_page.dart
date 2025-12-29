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
  List<Property> _ownedUnlisted = [];
  List<Property> _ownedRenting = [];
  List<Property> _ownedRented = [];
  List<Property> _ownedListed = [];
  
  List<Property> _tenantRented = [];
  
  bool _isLoading = true;
  String _currentRole = 'tenant';

  @override
  void initState() {
    super.initState();
    _currentRole = AppUser().role;
  
    int tabLength = _currentRole == 'owner' ? 4 : 1;
    _tabController = TabController(length: tabLength, vsync: this);
    _loadProperties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AppUser().id ?? 0;
      
      if (_currentRole == 'owner') {

        final owned = await PropertyService.getOwnedProperties(userId);
        if (mounted) {
          setState(() {
            _ownedUnlisted = owned.where((p) => 
                p.status == 'unlisted' || p.status == 'pending' || p.status == 'rejected').toList();
            _ownedListed = owned.where((p) => p.status == 'listed').toList();
            _ownedRenting = owned.where((p) => p.status == 'renting').toList();
            _ownedRented = owned.where((p) => p.status == 'rented').toList();
            _isLoading = false;
          });
        }
      } else {

        final rented = await PropertyService.getRentedProperties(userId);
        if (mounted) {
          setState(() {
            _tenantRented = rented;
            _isLoading = false;
          });
        }
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

  Future<void> _handleArchive(Property property) async {

    if (property.status != 'unlisted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only 'unlisted' properties can be archived."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Archive Property"),
        content: Text(
            "Are you sure you want to archive '${property.name}'?\n\nIt will be hidden from your list but kept in records."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Archive", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      final success = await PropertyService.archiveProperty(property.id);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Property archived successfully")),
          );
          _loadProperties(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to archive property")),
          );
        }
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

  Widget _buildPropertyList(List<Property> properties, PropertyMode mode) {
    if (properties.isEmpty) {
      return _buildEmptyState("No properties found.", Icons.home_work_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadProperties,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: properties.length,
        itemBuilder: (context, i) {
          final p = properties[i];
          if (mode == PropertyMode.owned) {
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
                 _handleArchive(p);
              },
            );
          } else {
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
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (AppUser().role != _currentRole) {
       _currentRole = AppUser().role;
       int tabLength = _currentRole == 'owner' ? 4 : 1;
       _tabController.dispose();
       _tabController = TabController(length: tabLength, vsync: this);
       _loadProperties(); // Reload data for new role
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        title: Text(
          _currentRole == 'owner' ? 'My Properties' : 'My Rentals',
          style: const TextStyle(color: Colors.white),
        ),
        bottom: _currentRole == 'owner' 
          ? TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Unlisted'),
                Tab(text: 'Listed'),
                Tab(text: 'Renting'),
                Tab(text: 'Rented'),
              ],
            )
          : null, // No tabs for tenant
      ),
      floatingActionButton: _currentRole == 'owner' 
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddPropertyPage()),
                );

                if (result == true) {
                  _loadProperties(); 
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Tenants usually don't add properties
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentRole == 'owner'
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPropertyList(_ownedUnlisted, PropertyMode.owned),
                    _buildPropertyList(_ownedListed, PropertyMode.owned),
                    _buildPropertyList(_ownedRenting, PropertyMode.owned),
                    _buildPropertyList(_ownedRented, PropertyMode.owned),
                  ],
                )
              : _buildPropertyList(_tenantRented, PropertyMode.rented),
    );
  }
}
