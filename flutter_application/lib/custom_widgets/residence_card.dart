import 'package:flutter/material.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/models/residence_summary.dart';

class ResidenceCard extends StatelessWidget {
  final ResidenceSummary residence;
  final void Function(String id) onTap;
  final void Function(bool newValue)? onFavoriteToggle;

  const ResidenceCard({
    super.key,
    required this.residence,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.8;
    final cardHeight = cardWidth * 0.8;

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
          child: Column(
            children: [
              // Image section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: cardHeight * 0.6,
                      width: double.infinity,
                      child: residence.imageUrl != null
                          ? Image.network(
                              residence.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Placeholder(),
                            ),
                    ),
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
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Text section 
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        residence.title,
                        style: AppTheme.heading1.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Beds, Baths, Area row
                      Row(
                        children: [
                          Icon(Icons.bed, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text('${residence.numBeds}'),
                          const SizedBox(width: 12),
                          Icon(Icons.bathtub, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text('${residence.numBaths}'),
                          const SizedBox(width: 12),
                          Icon(Icons.square_foot, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text('${residence.area} sqft'),
                        ],
                      ),

                      const Spacer(), // push price to bottom

                      // Price row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '\$${residence.price.toStringAsFixed(0)}',
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
