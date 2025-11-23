import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/action_button.dart';
import 'package:flutter_application/models/property.dart';

enum PropertyMode { owned, rented }

class PropertyManagementPage extends StatelessWidget {
  final Property property;
  final PropertyMode mode;

  const PropertyManagementPage({
    super.key,
    required this.property,
    required this.mode,
  });

  List<Map<String, dynamic>> getActionButtons() {
    if (mode == PropertyMode.owned) {
      return [
        {'icon': Icons.edit, 'label': 'Edit', 'action': () {}},
        {'icon': Icons.people, 'label': 'Tenant Record', 'action': () {}},
        {'icon': Icons.chair, 'label': 'Furniture List', 'action': () {}},
        {'icon': Icons.list_alt, 'label': 'Manage Listing', 'action': () {}},
        {'icon': Icons.report, 'label': 'Reported Issues', 'action': () {}},
      ];
    } else {
      // rented
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
    final buttons = getActionButtons();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Thumbnail
          property.thumbnailUrl != null && property.thumbnailUrl!.isNotEmpty
              ? Image.network(
                  property.thumbnailUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
                  property.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: ${property.status ?? "Unknown"}",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
