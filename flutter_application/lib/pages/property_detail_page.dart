import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/residence_summary.dart';

class PropertyDetailPage extends StatefulWidget {
  final ResidenceSummary residence;

  const PropertyDetailPage({super.key, required this.residence});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final residence = widget.residence; // easier reference
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Thumbnail image section
              SliverAppBar(
                expandedHeight: screenHeight * 0.4,
                pinned: true,
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      residence.imageUrl != null
                          ? Image.network(
                              residence.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Placeholder(),
                            ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: CircleAvatar(
                          backgroundColor:
                              Colors.white.withAlpha((0.7 * 255).toInt()),
                          child: IconButton(
                            onPressed: () {
                              // TODO: favorite toggle
                            },
                            icon: Icon(
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
                ),
              ),

              // Below content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        '${residence.title}', // TODO: Replace with actual title
                        style: AppTheme.heading1.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 8),

                      // Address
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${residence.title}', // TODO: Replace with address
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Rating
                      Row(
                        children: [
                          Icon(Icons.star, color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 4),
                          Text('${residence.title}', // TODO: Replace with rating
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Owner info + contact button
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey,
                              child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ), // TODO: owner profilePic, Use BackGround image later
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${residence.title}', // TODO: Replace with owner name
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                              onPressed: () {
                                // TODO: contact owner
                              },
                              style: ElevatedButton.styleFrom(      
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Icon(
                                Icons.chat,
                                color: Colors.white,
                              ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tab bar for content sections
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: AppTheme.primaryColor,
                        tabs: const [
                          Tab(text: 'Info'),
                          Tab(text: 'Gallery'),
                          Tab(text: 'Amenities'),
                          Tab(text: 'Rules'),
                        ],
                      ),

                      // Tab contents
                      SizedBox(
                        height: 600, // make scrollable part long enough
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Info Section
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _infoTile(Icons.bed, '${residence.numBeds} Beds'),
                                      _infoTile(Icons.bathtub, '${residence.numBaths} Baths'),
                                      _infoTile(Icons.square_foot, '${residence.area} sqft'),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '${residence.title}', // TODO: Replace with description
                                    style: const TextStyle(height: 1.5),
                                  ),
                                ],
                              ),
                            ),

                            // Gallery Section
                            const Center(
                              child: Text('Gallery Section (TODO)'),
                            ),

                            // Amenities Section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Amenities:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 12),
                                  Text('- Wi-Fi'),
                                  Text('- Air Conditioning'),
                                  Text('- Parking'),
                                  Text('- Swimming Pool'),
                                ],
                              ),
                            ),

                            // Rules Section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: const Text(
                                'Rules and Terms:\n\n'
                                '- No smoking\n'
                                '- No pets\n'
                                '- Minimum 6 months stay\n'
                                '- Security deposit required',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Add space for bottom fixed section
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed bottom section (price + rent button)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      '\$${residence.price}/month', // TODO: Replace with price
                      style: AppTheme.heading1.copyWith(
                        fontSize: 20,
                        color: AppTheme.primaryColor,
                      ),
                    ),

                    // Rent button
                    ElevatedButton(
                      onPressed: () {
                        // TODO: rent now action
                      },
                      style: AppTheme.primaryButton,
                      child: const Text('Rent Now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
