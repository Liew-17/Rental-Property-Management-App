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
  final cardWidth = screenWidth * 0.933;
  final cardHeight = (cardWidth * 0.7).clamp(350.0, 800.0); // remain within a suitable height

  return GestureDetector(
    onTap: () => onTap(residence.id),
    child: SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Image section
            SizedBox(
              height: cardHeight * 0.6,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: (residence.thumbnailUrl != null && residence.thumbnailUrl!.isNotEmpty)?
                              Image.network(
                                ApiService.buildImageUrl(residence.thumbnailUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: Icon(Icons.image)),
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.image)),
                              )
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (onFavoriteToggle != null) {
                          onFavoriteToggle!(!residence.isFavorited);
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor:
                            Colors.white.withAlpha((0.7 * 255).toInt()),
                        child: Icon(
                          residence.isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppTheme.favoritedColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      residence.title ?? "",
                      style: AppTheme.heading1.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Beds, Baths, Area row
                    Row(
                      children: [
                        Icon(Icons.bed, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text('${residence.numBedrooms}'),
                        const SizedBox(width: 10),
                        Icon(Icons.bathtub, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text('${residence.numBathrooms}'),
                        const SizedBox(width: 10),
                        Icon(Icons.square_foot, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text('${residence.landSize} sqft'),
                      ],
                    ),
                    const SizedBox(height: 15), 

                    // Price row at bottom-right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '\$${residence.price!.toStringAsFixed(0)}',
                          style: AppTheme.heading1.copyWith(
                            fontSize: 16,
                            color: AppTheme.primaryColor,
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
  );
}

}
