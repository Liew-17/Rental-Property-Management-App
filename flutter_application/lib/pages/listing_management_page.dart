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
  Residence? _residence;
  double? _suggestedPrice;
  var _allNecessaryCompleted = false;
  bool _isLoading = true;

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
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load property: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text("Listing Management")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_residence == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Failed to load property")),
      );
    }

    final statusColor = AppTheme.getStatusColor(_residence!.status);
    final statusLower = (_residence!.status ?? "").toLowerCase();
    
    final isListed = _residence!.status == "listed";
    // Check if property is in a rented state (rented or renting)
    final isRented = ["rented", "renting"].contains(statusLower);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Listing Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Header & Preview Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                // Info Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _residence!.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          (_residence!.status ?? "Unknown").toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Preview Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Preview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "This is how your property appears in search results.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions Title - Hidden if Rented
                if (!isRented) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isListed ? "Manage Listing" : "Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Action Buttons Grid - Hidden if Rented
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4, // Wide buttons
              ),
              delegate: SliverChildListDelegate(
                isRented 
                  ? [] // Empty list for rented state
                  : (isListed ? _getListedActions(context) : _getUnlistedActions(context)),
              ),
            ),
          ),

          // 3. Bottom Section (Stats or Checklist) - Hidden if Rented
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: isRented
                  ? const SizedBox.shrink() // Hide section for rented state
                  : (isListed
                      ? _buildListingStatsSection()
                      : MissingRequirementsSection(
                          residence: _residence!,
                          onChanged: (allCompleted) {
                        
                            Future.microtask(() {
                              if (mounted && _allNecessaryCompleted != allCompleted) {
                                setState(() => _allNecessaryCompleted = allCompleted);
                              }
                            });
                          },
                        )),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // --- Actions ---

  List<Widget> _getUnlistedActions(BuildContext context) {
    return [
      ActionButton(
        icon: Icons.edit_rounded,
        label: 'Edit Info',
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
      ActionButton(
        icon: Icons.publish_rounded,
        label: 'List Property',
        onTap: () => _handleListProperty(context),
      ),
    ];
  }

  List<Widget> _getListedActions(BuildContext context) {
    return [
      ActionButton(
        icon: Icons.people_alt_rounded,
        label: 'Requests',
        onTap: () {
          // TODO: Navigate to request page
        },
      ),
      ActionButton(
        icon: Icons.unpublished_rounded,
        label: 'Unlist',
        onTap: () {
          // TODO: connect to unlist endpoint
        },
      ),
    ];
  }

  void _handleListProperty(BuildContext context) {
    if (!_allNecessaryCompleted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please complete all required fields before listing.'),
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
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: _buildPricingSheet(
          parentContext: context,
          onConfirm: (price, deposit) async {
            if (price == null || price == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Price is required.")));
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
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to list property.")));
            }
          },
          suggestedPrice: _suggestedPrice,
        ),
      ),
    );
  }


  Widget _buildListingStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Performance",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatRow('Status', 'Active', Colors.green),
              _buildStatRow('Views', '124', Colors.black87),
              _buildStatRow('Requests', '8', Colors.black87),
              _buildStatRow('Favorites', '34', Colors.pink),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSheet({
    required void Function(double? price, double? deposit) onConfirm,
    required BuildContext parentContext,
    double? suggestedPrice,
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
            const SizedBox(height: 20),

            // AI Suggestion Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestedPrice != null
                              ? 'AI Suggested: RM ${suggestedPrice.toStringAsFixed(0)}'
                              : 'AI suggestion unavailable',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      
                      if (suggestedPrice != null)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: parentContext,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Disclaimer'),
                                content: const Text(
                                  'This price is provided by AI based on market data. '
                                  'Use at your own risk.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.help_outline, 
                              size: 20, 
                              color: AppTheme.primaryColor
                            ),
                          ),
                        ),
                    ],
                  ),
                
                  if (suggestedPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            priceController.text = suggestedPrice.toStringAsFixed(0);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Apply Suggestion', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Price Fields
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Monthly Rent (RM)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: depositController,
              decoration: InputDecoration(
                labelText: 'Deposit Amount (RM)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.savings_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(parentContext),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final double? price = double.tryParse(priceController.text);
                      final double? deposit = double.tryParse(depositController.text);
                      onConfirm(price, deposit);
                    },
                    style: AppTheme.primaryButton,
                    child: const Text('Publish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}