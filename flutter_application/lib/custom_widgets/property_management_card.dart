import 'package:flutter/material.dart';
import 'package:flutter_application/models/property.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/theme.dart';

class OwnedPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const OwnedPropertyCard({
    super.key,
    required this.property,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyCardBase(
      property: property,
      // Show delete only if not actively rented/listed to prevent accidents
      showDelete: property.status == "unlisted",
      onView: onView,
      onDelete: onDelete,
    );
  }
}

class RentedPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onView;

  const RentedPropertyCard({
    super.key,
    required this.property,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyCardBase(
      property: property,
      showDelete: false,
      onView: onView,
    );
  }
}

/// Base widget shared by both
class PropertyCardBase extends StatelessWidget {
  final Property property;
  final VoidCallback onView;
  final VoidCallback? onDelete;
  final bool showDelete;

  const PropertyCardBase({
    super.key,
    required this.property,
    required this.onView,
    this.onDelete,
    this.showDelete = false,
  });

  String _getLocationString() {
    final parts = [property.district, property.city, property.state]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? "Location not set" : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    // Now relying on AppTheme for consistent status colors
    final statusColor = AppTheme.getStatusColor(property.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== IMAGE ==========
              Container(
                width: 90, 
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                clipBehavior: Clip.hardEdge,
                child: (property.thumbnailUrl != null &&
                        property.thumbnailUrl!.isNotEmpty)
                    ? Image.network(
                        ApiService.buildImageUrl(property.thumbnailUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey));
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 30)),
              ),

              const SizedBox(width: 14),

              // ========== DETAILS ==========
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (property.status ?? "Unknown").toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),

                    // 2. Name (Primary Identifier)
                    Text(
                      property.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 3. Location (Context)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getLocationString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ========== ACTION BUTTONS ==========
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: onView,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    color: Colors.grey[400],
                    tooltip: "View Details",
                    constraints: const BoxConstraints(), 
                    padding: const EdgeInsets.all(8),
                  ),
                  if (showDelete) ...[
                    const SizedBox(height: 10),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red[300],
                      tooltip: "Delete",
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}