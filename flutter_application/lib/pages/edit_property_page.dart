import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/custom_widgets/feature_editor.dart';
import 'package:flutter_application/custom_widgets/gallery_editor.dart';
import 'package:flutter_application/custom_widgets/location_picker.dart';
import 'package:flutter_application/custom_widgets/residence_type_picker.dart';
import 'package:flutter_application/custom_widgets/section.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:image_picker/image_picker.dart';


class EditPropertyPage extends StatefulWidget {
  final int propertyId;

  const EditPropertyPage({super.key, required this.propertyId});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}



class _EditPropertyPageState extends State<EditPropertyPage>
    with SingleTickerProviderStateMixin {
  Residence? _residence;
  bool _isLoading = true;

  late TabController _tabController;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bedroomCtrl = TextEditingController();
  final _bathroomCtrl = TextEditingController();
  final _landCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final picker = ImagePicker();
  
  XFile? _thumbnail;
  String? _thumbnailUrl;
  // Location
  String? _state;
  String? _district;
  String? _city;
  String? _residenceType;

  // Features & Gallery
  String? _features;
  List<String>? _galleryUrls;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; 
      setState(() {}); 
    });
    _loadProperty();

  }

  Future<void> _loadProperty() async {
    
    try {
        final res = await PropertyService.getDetails(widget.propertyId);

        _residence = res;
        _nameCtrl.text = res.name;
        _titleCtrl.text = res.title ?? "";
        _descCtrl.text = res.description ?? "";
        _bedroomCtrl.text = res.numBedrooms?.toString() ?? "0";
        _bathroomCtrl.text = res.numBathrooms?.toString() ?? "0";
        _landCtrl.text = res.landSize?.toString() ?? "0";
        _rulesCtrl.text = res.rules ?? "";

        _thumbnailUrl = res.thumbnailUrl;
        _state = res.state;
        _district = res.district;
        _city = res.city;
        _addressCtrl.text = res.address ?? "";

        _features = res.features;
        _galleryUrls=res.gallery;
        _residenceType = res.residenceType;

        if (mounted) setState(() => _isLoading = false);
      } catch (e) {
        debugPrint("Failed to load property: $e");
        if (mounted) {
          Navigator.pop(context); 
        }
    }
  }
  
  Future<void> _updateGallery() async {
    final images = await PropertyService.getGalleryImages(widget.propertyId);
    setState(() {
      _galleryUrls = images ?? [];
    });
  }

  Future<void> _saveInfo() async {
    if (_residence == null) return;

    final Map<String, dynamic> updateFields = {
      "name": _nameCtrl.text,
      "title": _titleCtrl.text,
      "description": _descCtrl.text,
      "state": _state,
      "city": _city,
      "district": _district,
      "address": _addressCtrl.text,
      "features": _features,
      "rules": _rulesCtrl.text,
      "num_bedrooms": int.tryParse(_bedroomCtrl.text) ?? 0,
      "num_bathrooms": int.tryParse(_bathroomCtrl.text) ?? 0,
      "land_size": double.tryParse(_landCtrl.text) ?? 0.0,
      "residence_type": _residenceType
    };

    final success = await PropertyService.updateResidence(
      propertyId: _residence!.id,
      fields: updateFields,
      thumbnail: _thumbnail, 
    );

    if (success) {
      if(mounted){
        Navigator.pop(context, true);
      }
    } else {
      debugPrint("Failed to Update");
      if(mounted){
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _pickThumbnail() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnail = pickedFile;
      });
    }
  }

  Widget buildThumbnail({XFile? thumbnail, String? thumbnailUrl, double height = 300}) {
  // Case 1: Picked file exists
  if (thumbnail != null) {
    return kIsWeb
        ? Image.network(
            thumbnail.path,
            fit: BoxFit.cover,
            height: height,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
          )
        : Image.file(
            File(thumbnail.path),
            fit: BoxFit.cover,
            height: height,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
          );
  }

  // Case 2: Use URL
  if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
    return Image.network(
      ApiService.buildImageUrl(thumbnailUrl),
      fit: BoxFit.cover,
      height: height,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
    );
  }

  // Case 3: No image found → default
  return Container(
    height: height,
    width: double.infinity,
    color: Colors.grey[300],
    child: const Icon(Icons.image, size: 50),
  );
}
  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Residence")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Residence"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "Info"),
            Tab(text: "Gallery"),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveInfo,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1 - info
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

          Center(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: buildThumbnail(thumbnail: _thumbnail, thumbnailUrl: _thumbnailUrl)
                ),

                Positioned(
                    bottom: 8,
                    right: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .8), // Transparent white background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
                        onPressed: _pickThumbnail,
                      ),
                    ),
                  ),
              ],
            ),
          ),
            const SizedBox(height: 20),

                section(
                  "Basic Info",
                  Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: "Title"),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),

                section(
                    "House Details",
                    Row(
                      children: [
                        // Bedrooms
                        Expanded(
                          child: TextFormField(
                            controller: _bedroomCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: "Bedrooms",
                              prefixIcon: Icon(Icons.bed, color: AppTheme.primaryColor),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Bathrooms
                        Expanded(
                          child: TextFormField(
                            controller: _bathroomCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: "Bathrooms",
                              prefixIcon: Icon(Icons.bathtub, color: AppTheme.primaryColor),
                            ),
                          ),
                        ),

 

 

                        const SizedBox(width: 10),

                        // Land Size
                        Expanded(
                          child: TextFormField(
                            controller: _landCtrl,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'), // allows decimal
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: "Area (sqft)",
                              prefixIcon: Icon(Icons.square_foot, color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                                       

                section(
                  "Residence Type",
                  ResidenceTypePicker(
                    initialResidenceType: _residenceType,
                    onChanged: (value) {
                        setState(() {
                          _residenceType = value;
                        });
                      },
                  )
                ),

                section(
                  "Location",
                  Column(
                    children: [
                      LocationPicker(
                        initialState: _state,
                        initialDistrict: _district,
                        initialCity: _city,
                        onChanged: (s, d, c) {
                          _state = s;
                          _district = d;
                          _city = c;
                        },
                      ),
                      TextField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(                
                          labelText: "Address (Street, etc.)",
                          prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),),
                      )
                    
                    ]
                  )
                ),

                section(
                  "Features",
                  FeatureEditor(
                    initialFeatureString: _features??"",
                    onChanged: (combined) {
                      setState(() {
                        _features = combined;
                      });
                    },
                  ),
                ),

                section(
                  "House Rules",
                  TextField(
                    controller: _rulesCtrl,
                    decoration: const InputDecoration(
                      labelText: "Rules & Terms",
                      hintText: "E.g. No smoking inside, No pets allowed...",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                  ),
                ),
              ],
            ),
          ),

          // Tab 2 - gallery
          Padding(
            padding: const EdgeInsets.all(16),
            child: GalleryEditor(
                urls: _galleryUrls??[] ,

                fetchGallery: () async {
                  final images = await PropertyService.getGalleryImages(widget.propertyId);
                  await _updateGallery();
                  return images ?? [];
                },

                uploadImage: (file) async {
                  PropertyService.addGalleryImage(propertyId: widget.propertyId, galleryImage: file);
                  
                },

                deleteImage: (url) async {
                  PropertyService.deleteGalleryImage(propertyId: widget.propertyId, imageUrl: url);
                },
                  
              )

          ),
        ],
      ),
    );
  }
}

