import 'package:flutter/material.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/api_service.dart';
import '../theme.dart';
import 'package:galleryimage/galleryimage.dart';
import 'package:flutter_application/services/property_service.dart';

class PropertyDetailPage extends StatefulWidget {
  final int propertyId;

  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Residence> _residenceFuture;

  List<String> listOfUrls = []; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Fetch the residence details
    _residenceFuture = PropertyService.getDetails(widget.propertyId);
  }

  Widget _infoTile(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Residence>(
        future: _residenceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading indicator
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Property not found"));
          }

          final residence = snapshot.data!;
          listOfUrls = residence.gallery??[];

          return Stack(
            children: [
              // Scrollable content
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.4,
                    pinned: true,
                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          residence.thumbnailUrl != null
                              ? Image.network(
                                  ApiService.buildImageUrl(residence.thumbnailUrl!),
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
                              backgroundColor: Colors.white.withAlpha((0.7 * 255).toInt()),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            residence.name,
                            style: AppTheme.heading1.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: AppTheme.primaryColor, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  residence.address ?? "",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.star, color: AppTheme.primaryColor, size: 18),
                              const SizedBox(width: 4),
                              Text(residence.status ?? "",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  residence.ownerName ?? "",
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
                          SizedBox(
                            height: 600,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _infoTile(Icons.bed,
                                              '${residence.numBedrooms ?? '-'} Beds'),
                                          _infoTile(Icons.bathtub,
                                              '${residence.numBathrooms ?? '-'} Baths'),
                                          _infoTile(Icons.square_foot,
                                              '${residence.landSize ?? '-'} sqft'),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        residence.description ?? "",
                                        style: const TextStyle(height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),

                                // Gallery Section
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20.0, left: 10, right: 10),
                                  child: GalleryImage(
                                    imageUrls: listOfUrls,
                                    numOfShowImages: listOfUrls.length > 6
                                        ? 6
                                        : listOfUrls.length,
                                    galleryBackgroundColor:
                                        AppTheme.backgroundColor,
                                    titleGallery: "",
                                  ),
                                ),

                                // Amenities Section
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Amenities:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
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
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        Text(
                          '\$${residence.price?.toStringAsFixed(2) ?? '-'} / month',
                          style: AppTheme.heading1.copyWith(
                            fontSize: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
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
          );
        },
      ),
    );
  }
}
