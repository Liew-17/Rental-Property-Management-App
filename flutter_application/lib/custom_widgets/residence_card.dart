import 'package:flutter/material.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/theme.dart';

class ResidenceCard extends StatelessWidget {
  final Residence residence;
  final void Function(int id) onTap;
  final void Function(bool newValue)? onFavoriteToggle;

  const ResidenceCard({
    super.key,
    required this.residence,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust width slightly to ensure it fits well with margins
    final cardWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.92;
    // Dynamic height based on width, clamped to reasonable limits
    final cardHeight = (cardWidth * 0.8).clamp(340.0, 450.0);

    // Helper to construct the location string from available parts
    String getLocationString() {
      final parts = [
        residence.district,
        residence.city,
        residence.state
      ].where((s) => s != null && s.isNotEmpty).toList();
      
      return parts.isEmpty ? "Location not available" : parts.join(', ');
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap(residence.id),
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            clipBehavior: Clip.hardEdge,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Image Section (Top Half) ===
                Expanded(
                  flex: 6, // Takes up 60% of card height
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: (residence.thumbnailUrl != null &&
                                residence.thumbnailUrl!.isNotEmpty)
                            ? Image.network(
                                ApiService.buildImageUrl(residence.thumbnailUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey)),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Center(
                                    child: Icon(Icons.image,
                                        size: 40, color: Colors.grey)),
                              ),
                      ),
                      
                      // Favorite Button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            if (onFavoriteToggle != null) {
                              onFavoriteToggle!(!residence.isFavourited);
                            }
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Icon(
                              residence.isFavourited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: AppTheme.favoritedColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // === Content Section (Bottom Half) ===
                Expanded(
                  flex: 4, 
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Title
                        Text(
                          (residence.title != null && residence.title!.isNotEmpty) 
                              ? residence.title! 
                              : residence.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // 2. Location Row
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                getLocationString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // 3. Features Row (Beds, Baths, Size)
                        Row(
                          children: [
                            _buildFeature(Icons.bed, '${residence.numBedrooms ?? '-'}'),
                            const SizedBox(width: 12),
                            _buildFeature(Icons.bathtub, '${residence.numBathrooms ?? '-'}'),
                            const SizedBox(width: 12),
                            _buildFeature(Icons.square_foot, 
                                residence.landSize != null && residence.landSize! > 0
                                  ? '${residence.landSize!.toStringAsFixed(0)} sqft'
                                  : '- sqft'
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // 4. Footer: Type & Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Property Type Label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey[300]!)
                              ),
                              child: Text(
                                residence.residenceType ?? 'Residence',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            // Price
                            Text(
                              residence.price != null && residence.price! > 0
                                  ? 'RM ${residence.price!.toStringAsFixed(0)} /mo'
                                  : 'Price TBD',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for features
  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}