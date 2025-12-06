import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/action_button.dart';
import 'package:flutter_application/custom_widgets/missing_requirement_section.dart';
import 'package:flutter_application/custom_widgets/residence_card.dart';
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
    double? _suggestedPrice;
    var _allNecessaryCompleted = false;

    @override
    void initState() {
      super.initState();
      _loadProperty();
    }

    Future<void> _loadProperty() async {
      try {
        final Residence data = await PropertyService.getDetails(widget.propertyId);
        final double? price = await PropertyService.predictProperty(propertyId: widget.propertyId);
        if (!mounted) return;

        setState(() {
          _residence = data;
          _suggestedPrice = price;
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
        body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // -------- Header + Badge --------
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Property Name - Large & Bold
                          Text(
                            _residence!.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22, // larger heading
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _residence!.status == "listed"
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _residence!.status == "listed" ? "Listed" : "Not Listed",
                              style: TextStyle(
                                color: _residence!.status == "listed"
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // -------- Preview Section --------
                      const Text(
                        'Preview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Click on the card below to view details.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 148, 148, 148),
                        ),
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

                      const SizedBox(height: 25),

                      if(_residence!.status == "listed") 
                        _buildListedView(context)
                      else 
                        _buildUnlistedView(context),


                    ],
                  ),
                ),
              ),
      
      
        );
      
    }

    Widget _buildListedView(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          //Action buttons
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActionButton(
                  icon: Icons.people,
                  label: 'Request',
                  onTap: () {
                    //TODO: go to request page
                  },
                ),
                ActionButton(
                  icon: Icons.cancel,
                  label: 'Unlist',
                  onTap: () {
                    //TODO: connect to unlist endpoint
                  },
                ),

                
              ],
            ),
          ),

          _buildListingStatsSection(),

        ],
      );
    }

    Widget _buildUnlistedView(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // -------- Action Buttons --------
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      if (mounted) _loadProperty();
                    });
                  },
                ),
                const SizedBox(width: 100),
                ActionButton(
                  icon: Icons.upload,
                  label: 'List',
                  onTap: () {
                    if (!_allNecessaryCompleted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Missing Information'),
                          content: const Text('Please complete all required fields before listing.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: _buildPricingSheet(
                          parentContext: context,
                          onConfirm: (price, deposit) async {
                            if (price == null || price == 0) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Error"),
                                  content: const Text("Price is required."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
                                ),
                              );
                              return;
                            }

                            final success = await PropertyService.listProperty(
                              propertyId: widget.propertyId,
                              price: price,
                              deposit: deposit,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              Navigator.pop(context);
                              _loadProperty();
                            } else {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Error"),
                                  content: const Text("Failed to list property."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
                                ),
                              );
                            }
                          },
                          suggestedPrice: _suggestedPrice,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // -------- Missing Requirements Section --------
          MissingRequirementsSection(
            residence: _residence!,
            onChanged: (allCompleted) {
              _allNecessaryCompleted = allCompleted;
            },
          ),

          const SizedBox(height: 25),
        ],
      );
    }


    Widget _buildListingStatsSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Listing Performance",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //TODO: implement analytics
                _buildStatRow('Status', 'Active'),
                _buildStatRow('Views', '124'),
                _buildStatRow('Requests', '8'),
                _buildStatRow('Favorites', '34'),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildStatRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }


}

  Widget _buildPricingSheet({
    required void Function(double? price, double? deposit) onConfirm,
    required BuildContext parentContext,
    double? suggestedPrice, // AI price, just display
  }) {
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

          Row(
          children: [
            const Icon(Icons.lightbulb, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Text(
                    suggestedPrice != null
                        ? 'AI Suggested Price: RM ${suggestedPrice.toStringAsFixed(2)}'
                        : 'AI suggested price not available',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (suggestedPrice != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        // Show a dialog with more info
                            showDialog(
                              context: parentContext,
                              builder: (_) => AlertDialog(
                                title: const Text('AI Price Info'),
                                content: const Text(
                                  'This price is suggested by our AI based on similar properties. '
                                  'You can use it or set your own price.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(parentContext),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.help_outline,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (suggestedPrice != null)
                  TextButton(
                    onPressed: () {
                      priceController.text = suggestedPrice.toStringAsFixed(2);
                    },
                    child: const Text('Use'),
                  ),
              ],
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
