import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/file_uploader.dart';
import 'package:flutter_application/data/features_data.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/chat_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/rent_service.dart';
import 'package:flutter_application/services/user_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Fetch the residence details
    _residenceFuture = PropertyService.getDetails(widget.propertyId);
    

    _residenceFuture.then((residence) {
      if (mounted) {
        setState(() {
          // Check if viewed by owner
          _resolvedViewOnly = widget.viewOnly 
              || (residence.ownerId == AppUser().id)
              || (AppUser().role == 'owner');
        }); 
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _infoTile(IconData icon, String label, String subLabel) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          label, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        Text(
          subLabel, 
          style: TextStyle(color: Colors.grey[600], fontSize: 12)
        ),
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

          // Parse amenities (features)
          List<String> amenities = [];
          if (residence.features != null && residence.features!.isNotEmpty) {
            amenities = residence.features!.split('|');
          }

          return Stack(
            children: [
              // Scrollable content
              CustomScrollView(
                slivers: [
                  // --- App Bar Image ---
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.4,
                    pinned: true,
                    backgroundColor: Colors.white,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const BackButton(color: Colors.white),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          residence.thumbnailUrl != null && residence.thumbnailUrl!.isNotEmpty
                              ? Image.network(
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
                                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                                      ),
                                ),
                          // Favorite Button
                          Positioned(
                            top: 40,
                            right: 20,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    residence.isFavourited = !residence.isFavourited;
                                    UserService.toggleFavourite(residence.id);   
                                  });
                                },
                                icon: Icon(
                                  residence.isFavourited
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
                  ),

                  // --- Content ---
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // 1. Header Section (Padded)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                residence.title??"No Title",
                                style: const TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Address
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on,
                                      color: AppTheme.primaryColor, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      [residence.address, residence.district, residence.city, residence.state]
                                          .where((s) => s != null && s.isNotEmpty)
                                          .join(", "),
                                      style: TextStyle(color: Colors.grey[700], height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Owner Profile Placeholder
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!)
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey[300], 
                                      backgroundImage: (residence.ownerPicUrl != null && residence.ownerPicUrl!.isNotEmpty)
                                          ? NetworkImage(ApiService.buildImageUrl(residence.ownerPicUrl!))
                                          : null, 
                                      child: (residence.ownerPicUrl == null || residence.ownerPicUrl!.isEmpty)
                                          ? const Icon(Icons.person, color: Colors.white, size: 28)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            residence.ownerName ?? "Property Owner",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const Text(
                                            "Landlord",
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_resolvedViewOnly)
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatPage(
                                                propertyId: residence.id, 
                                                tenantId: AppUser().id!, 
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        color: AppTheme.primaryColor,
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. TabBar (Full Width - No Horizontal Padding)
                        TabBar(
                          controller: _tabController,
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppTheme.primaryColor,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Info'),
                            Tab(text: 'Gallery'),
                            Tab(text: 'Features'),
                            Tab(text: 'Rules'),
                          ],
                        ),
                        
                        const SizedBox(height: 20),

                        // 3. Tab Views
                        SizedBox(
                          height: 400, // Fixed height for tab content area
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // --- Info Tab ---
                              SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16)
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _infoTile(Icons.bed, '${residence.numBedrooms ?? '-'}', 'Bedrooms'),
                                          Container(width: 1, height: 40, color: Colors.grey[300]),
                                          _infoTile(Icons.bathtub, '${residence.numBathrooms ?? '-'}', 'Bathrooms'),
                                          Container(width: 1, height: 40, color: Colors.grey[300]),
                                          _infoTile(Icons.square_foot, 
                                            residence.landSize != null ? residence.landSize!.toStringAsFixed(0) : '-', 
                                            'Sqft'
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Description",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      residence.description ?? "No description provided.",
                                      style: TextStyle(height: 1.6, color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                              ),

                              // --- Gallery Tab ---
                              listOfUrls.isEmpty 
                                ? Container(
                                    alignment: Alignment.center,
                                    child: const Text("No images available")
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: GalleryImage(
                                      imageUrls: listOfUrls,
                                      numOfShowImages: listOfUrls.length,
                                      galleryBackgroundColor: Colors.white,
                                      titleGallery: "",
                                    ),
                                  ),

                              SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                child: amenities.isEmpty 
                                  ? Container(
                                      height: 200,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.list_alt, size: 40, color: Colors.grey[300]),
                                          const SizedBox(height: 10),
                                          const Text("No features listed", style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 12, // Horizontal gap
                                      runSpacing: 12, // Vertical gap
                                      children: amenities.map((feature) {
                                        final icon = FeaturesData.getFeatureIcon(feature);
                                        // Calculate width for 3 columns (Screen width - padding - spacing) / 3
                                        final itemWidth = (MediaQuery.of(context).size.width - 40 - 24) / 3;

                                        return Container(
                                          width: itemWidth,
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.grey.shade100),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.03),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.05),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                feature.trim(),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 11, 
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              ),
                                      
                    
                              SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Deposit Section
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2))
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Security Deposit",
                                            style: TextStyle(
                                              fontSize: 14, 
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (residence.deposit != null && residence.deposit! > 0)
                                                ? "RM ${residence.deposit!.toStringAsFixed(0)}"
                                                : "No Deposit Required",
                                            style: const TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    const Text(
                                      "House Rules",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (residence.rules != null && residence.rules!.isNotEmpty)
                                          ? residence.rules!
                                          : "No specific rules provided by the owner. Standard tenancy agreements apply.\n\n• Treat the property with respect.\n• Report issues promptly.\n• Follow local community guidelines.",
                                      style: TextStyle(height: 1.6, color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
                ],
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black.withValues(alpha: (0.1)),
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Price", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            residence.price != null && residence.price! > 0
                                ? 'RM ${residence.price!.toStringAsFixed(0)} / mo'
                                : 'Price TBD',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (!_resolvedViewOnly)
                        ElevatedButton(
                          onPressed: () async {
                 
                            final hasPending = await RentService.checkPendingRequest(
                              userId: AppUser().id!,
                              propertyId: widget.propertyId,
                            );

                            if (!context.mounted) return;

                            if (hasPending) {
               
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("You have already sent a request for this property."),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {

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
                                      Navigator.pop(context); 
                                    },
                                  );
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Rent Now',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                    ],
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

  final int _maxAdvanceDays = 30; // Increased window slightly

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start Date
            const Text("Start Date", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: firstDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_startDate != null
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : "Select Date"),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            const Text("Duration (Months)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_duration > 1) setState(() => _duration--);
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  "$_duration",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _duration++),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // File Upload
            const Text("Financial Documents", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
          child: const Text("Submit Request"),
        ),
      ],
    );
  }
}