import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/action_button.dart';
import 'package:flutter_application/models/property.dart';
import 'package:flutter_application/pages/edit_property_page.dart';
import 'package:flutter_application/pages/listing_management_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/property_service.dart';

enum PropertyMode { owned, rented }

class PropertyManagementPage extends StatefulWidget {
  final int propertyId;     // only pass ID now
  final PropertyMode mode;

  const PropertyManagementPage({
    super.key,
    required this.propertyId,
    required this.mode,
  });

  @override
  State<PropertyManagementPage> createState() => _PropertyManagementPageState();
}

class _PropertyManagementPageState extends State<PropertyManagementPage> {
  Property? property;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    setState(() => loading = true);

    try {
      final fullProperty =
          await PropertyService.getDetails(widget.propertyId);
      setState(() {
        property = fullProperty;
        loading = false;
      });
    } catch (e) {
      debugPrint("Failed to load property: $e");
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> getActionButtons(BuildContext context) {
    if (widget.mode == PropertyMode.owned) {
      return [
        {
          'icon': Icons.edit,
          'label': 'Edit',
          'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EditPropertyPage(propertyId: widget.propertyId),
              ),
            ).then((_) {
              _loadProperty(); // refresh after pop
            });
          }
        },
        {'icon': Icons.people, 'label': 'Tenant Record', 'action': () {}},
        {'icon': Icons.chair, 'label': 'Furniture List', 'action': () {}},
        {'icon': Icons.list_alt, 'label': 'Manage Listing', 'action': () {
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ListingManagementPage(propertyId: widget.propertyId),
              ),
            );
        }},
        {'icon': Icons.report, 'label': 'Reported Issues', 'action': () {}},
      ];
    } else {
      return [
        {'icon': Icons.visibility, 'label': 'View Details', 'action': () {}},
        {'icon': Icons.message, 'label': 'Contact Owner', 'action': () {}},
        {'icon': Icons.payment, 'label': 'Pay Rent', 'action': () {}},
        {'icon': Icons.report, 'label': 'Report Issue', 'action': () {}},
        {'icon': Icons.assignment, 'label': 'View Contract', 'action': () {}},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (property == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load property")),
      );
    }

    final buttons = getActionButtons(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Thumbnail
          property!.thumbnailUrl != null &&
                  property!.thumbnailUrl!.isNotEmpty
              ? Image.network(
                  ApiService.buildImageUrl(property!.thumbnailUrl!),
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 64),
                    );
                  },
                )
              : Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 64),
                ),

          const SizedBox(height: 8),

          // Name + Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property!.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: ${property!.status ?? "Unknown"}",
                  style:
                      TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Button Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
                children: buttons
                    .map(
                      (b) => ActionButton(
                        icon: b['icon'],
                        label: b['label'],
                        onTap: b['action'],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}