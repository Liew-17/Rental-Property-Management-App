import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/file_uploader.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/rent_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import 'package:galleryimage/galleryimage.dart';
import 'package:flutter_application/services/property_service.dart';

class PropertyDetailPage extends StatefulWidget {
  final int propertyId;
  final bool viewOnly;

  const PropertyDetailPage({super.key, required this.propertyId, required this.viewOnly});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Residence> _residenceFuture;

  bool _resolvedViewOnly = true; 

  List<String> listOfUrls = []; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Fetch the residence details
    _residenceFuture = PropertyService.getDetails(widget.propertyId);

    _residenceFuture.then((residence) {
      setState(() {
        _resolvedViewOnly = widget.viewOnly ? true : (residence.ownerId == AppUser().id); // check if it is owned by the current user
      }); 
    });

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
          final listOfUrls = (residence.gallery ?? [])
            .map((item) => ApiService.buildImageUrl(item))
            .toList();

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
                          residence.thumbnailUrl != null?
                              Image.network(
                                  ApiService.buildImageUrl(residence.thumbnailUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
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
                              if (!_resolvedViewOnly)
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
                        if (!_resolvedViewOnly)
                          ElevatedButton(
                            onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return RentRequestDialog(
                                      onSubmit: (startDate, duration, files) {
                                        RentService.sendRentRequest(
                                            propertyId: widget.propertyId,
                                            userId: AppUser().id!,
                                            startDate: startDate,
                                            duration: duration,
                                            files: files
                                        );

                                        Navigator.pop(context); // Close the dialog
                                      },
                                    );
                                  },
                                );

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

class RentRequestDialog extends StatefulWidget {
  final void Function(DateTime startDate, int duration, List<XFile> files) onSubmit;

  const RentRequestDialog({super.key, required this.onSubmit});

  @override
  State<RentRequestDialog> createState() => _RentRequestDialogState();
}

class _RentRequestDialogState extends State<RentRequestDialog> {
  DateTime? _startDate;
  int _duration = 1;
  List<XFile> _files = [];

  final int _maxAdvanceDays = 15;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(Duration(days: _maxAdvanceDays));

    return AlertDialog(
      title: const Text("Rent Request"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Start Date"),
              subtitle: Text(_startDate != null
                  ? DateFormat('yyyy-MM-dd').format(_startDate!)
                  : "Select a date"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: firstDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Duration (months)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Label on the left
                Flexible(
                  child: Text(
                    "Duration (months):",
                    softWrap: true,
                  ),
                ),

                // Duration + buttons on the right
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_duration > 1) {
                          setState(() {
                            _duration--;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "$_duration",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _duration++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            
            // File upload widget
            XFileUploadWidget(
              onFilesChanged: (files) {
                setState(() {
                  _files = files;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _startDate == null || _files.isEmpty
              ? null
              : () {
                  widget.onSubmit(_startDate!, _duration, _files);
                },
          style: AppTheme.primaryButton,
          child: const Text("Submit Rent Request"),
          
        ),
      ],
    );
  }
}

