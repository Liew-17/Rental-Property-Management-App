import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/action_button.dart';
import 'package:flutter_application/custom_widgets/missing_requirement_section.dart';
import 'package:flutter_application/custom_widgets/residence_card.dart';
import 'package:flutter_application/models/property.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/pages/edit_property_page.dart';
import 'package:flutter_application/pages/property_detail_page.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';

class ListingManagementPage extends StatefulWidget {
  final int propertyId;

  const ListingManagementPage({super.key, required this.propertyId});

  @override
  State<ListingManagementPage> createState() => _ListingManagementPageState();
}

class _ListingManagementPageState extends State<ListingManagementPage> {
    Residence? _residence ;
    var _allNecessaryCompleted = false;

    @override
    void initState() {
      super.initState();
      _loadProperty();
    }

    Future<void> _loadProperty() async {
      try {
        final Residence data = await PropertyService.getDetails(widget.propertyId);

        if (!mounted) return;

        setState(() {
          _residence = data;

        });

      } catch (e) {
        debugPrint("Failed to load property: $e");
        if (mounted) Navigator.pop(context);
      }
    }

    List<RequirementStatus> buildRequirements(Residence residence) {
      bool photosOk = residence.thumbnailUrl != null &&
                      residence.thumbnailUrl!.isNotEmpty;

      List<String> missingLocation = [];

      if (residence.state?.isEmpty ?? true) missingLocation.add("State");
      if (residence.district?.isEmpty ?? true) missingLocation.add("District");
      if (residence.city?.isEmpty ?? true) missingLocation.add("City");
      if (residence.address?.isEmpty ?? true) missingLocation.add("Street Address");

      bool locationOk = missingLocation.isEmpty;



      List<String> missing = [];

      if (residence.numBedrooms == null) missing.add("bedrooms");
      if (residence.numBathrooms == null) missing.add("bathrooms");
      if (residence.landSize == null||residence.landSize == 0.0) missing.add("land size");
      if (residence.residenceType == null || residence.residenceType!.isEmpty) missing.add("type");
    
      bool detailsOk = missing.isEmpty;

      bool titleOk = residence.title?.isNotEmpty ?? false;
      bool descriptionOk = residence.description?.isNotEmpty ?? false;

      return [
        RequirementStatus(
          label: titleOk ? "Title" : "Title (Missing)",
          completed: titleOk,
        ),
        RequirementStatus(
          label: descriptionOk ? "Description" : "Description (Missing)",
          completed: descriptionOk,
        ),
        RequirementStatus(
          label: photosOk ? "Property Photos" : "Property Photos (Missing thumbnail)",
          completed: photosOk,
        ),
        RequirementStatus(
          label: locationOk 
              ? "Location Details" 
              : "Location Details (Missing: ${missingLocation.join(', ')})",
          completed: locationOk,
        ),
        RequirementStatus(
          label: detailsOk
              ? "Residence Details"
              : "Residence Details (Missing: ${missing.join(', ')})",
          completed: detailsOk,
        ),
      ];
    }

    @override
    Widget build(BuildContext context) {
      
      if(_residence == null){
        return Scaffold(
            appBar: AppBar(title: const Text("Listing Management")),
            body: const Center(child: CircularProgressIndicator()),
          );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Listing Management', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          scrolledUnderElevation: 0,            
        ),
        body: Center(
          child: _residence!.status == "listed"
              ? _buildListedView(context)
              : _buildUnlistedView(context),
        ),
      
        bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Property info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _residence!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height:10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _residence!.status == "listed"
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _residence!.status == "listed" ? "Listed" : "Not Listed",
                              style: TextStyle(
                                color: _residence!.status == "listed"
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    ],
                  ),

                  // Action buttons 
                  Row(
                    children: [
                    if (_residence!.status != "listed") 
                      ActionButton(
                        icon: Icons.edit,
                        label: 'Edit',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPropertyPage(propertyId: _residence!.id),
                            ),
                          ).then((_) {
                            if (mounted) {
                              _loadProperty();
                            }
                          });
                        },
                      ),
                      SizedBox(width: 20),
                      if (_residence!.status != "listed") 
                          ActionButton(
                          icon: Icons.upload,
                          label: 'List',
                          onTap: () { // TODO: Validate missing fields

                            if (!_allNecessaryCompleted) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Missing Information'),
                                  content: const Text(
                                      'Please complete all required fields before listing.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK')),
                                  ],
                                ),
                              );
                              return;
                            }

                              showDialog(
                                context: context,
                                barrierDismissible: true, // allows tap outside to dismiss
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                    child: _buildPricingSheet(
                                          parentContext: context,
                                          onConfirm: (price, deposit) {
                                            // TODO: handle confirm listing logic here
                                            // Example:
                                            // print('Price: $price, Deposit: $deposit');
                                            Navigator.pop(context); 
                                      },
                                    ), 
                                  );
                                },
                              );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
        );
      
    }

    Widget _buildListedView(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your property is currently listed.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(

              onPressed: () {
                // TODO: Implement unlist functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Unlist Property'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // TODO: Implement view requests
              },
              child: const Text('View Requests'),
            ),
          ],
        );
      }

    Widget _buildUnlistedView(BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    kToolbarHeight - 
                    MediaQuery.of(context).padding.top - 
                    100, 
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Property Card ---
                    const Text(
                      'Preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'click on following card to view details',
                      style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 148, 148, 148)),
                    ),
                    const SizedBox(height: 20),

                    ResidenceCard(
                      residence: _residence!,
                      onTap: (id) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PropertyDetailPage(propertyId: id, viewOnly: true),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- Missing Attributes Section ---
                    MissingRequirementsSection(
                      residence: _residence!,
                      onChanged: (allCompleted) {
                          _allNecessaryCompleted = allCompleted;
                      },
                    ),

                    const SizedBox(height: 25),
      
                  ],
                ),
              ),
            ),
          ),
        );
    }
}

Widget _buildPricingSheet({required void Function(double? price, double? deposit) onConfirm, required BuildContext parentContext}) {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController depositController = TextEditingController();

  return Padding(
    padding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set Pricing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Price field
          TextField(
            controller: priceController,
            decoration: const InputDecoration(
              labelText: 'Price (RM)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Deposit field
          TextField(
            controller: depositController,
            decoration: const InputDecoration(
              labelText: 'Deposit (RM)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Optional AI Suggest button
          ActionButton(
            icon: Icons.lightbulb,
            label: 'AI Suggest',
            onTap: () {
              // TODO: implement AI suggest logic
            },
          ),
          const SizedBox(height: 20),

          // Confirm List button
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(parentContext); // closes the sheet
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final double? price = double.tryParse(priceController.text);
                    final double? deposit = double.tryParse(depositController.text);
                    onConfirm(price, deposit); // your callback
                  },
                  style: AppTheme.primaryButton,
                  child: const Text('Confirm List'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}