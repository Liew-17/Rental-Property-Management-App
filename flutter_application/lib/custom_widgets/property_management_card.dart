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
      showDelete: property.status=="unlisted"? true : false,
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

    @override
    Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
    
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (property.thumbnailUrl != null && property.thumbnailUrl!.isNotEmpty)
                  ? Image.network(
                      ApiService.buildImageUrl(property.thumbnailUrl!),
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace){
                            return Container(
                            height: 80,
                            width: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 32),
                          );
                      },
                    )
                  : Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 32),
                    ),
            ),

            const SizedBox(width: 12),

            // ========== TEXT ==========
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  if (property.title != null && property.title!.isNotEmpty)
                    Text(property.title!,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text(
                    "Status: ${property.status ?? "Unknown"}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ========== BUTTONS HORIZONTAL ==========
            Row(
              children: [
                IconButton(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility),
                  color: AppTheme.primaryColor,
                  tooltip: "View",
                ),
                if (showDelete)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    tooltip: "Delete",
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
