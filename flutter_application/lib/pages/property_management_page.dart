import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/action_button.dart';
import 'package:flutter_application/models/property.dart';
import 'package:flutter_application/pages/edit_property_page.dart';
import 'package:flutter_application/pages/issue_list_page.dart';
import 'package:flutter_application/pages/leases_page.dart';
import 'package:flutter_application/pages/listing_management_page.dart';
import 'package:flutter_application/pages/pay_rent_page.dart';
import 'package:flutter_application/pages/report_issue_page.dart';
import 'package:flutter_application/pages/request_list_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';

enum PropertyMode { owned, rented }

class PropertyManagementPage extends StatefulWidget {
  final int propertyId;
  final PropertyMode mode;

  const PropertyManagementPage({
    super.key,
    required this.propertyId,
    required this.mode,
  });

  @override
  State<PropertyManagementPage> createState() => _PropertyManagementPageState();
}

class _PropertyManagementPageState extends State<PropertyManagementPage> {
  Property? property;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    setState(() => loading = true);

    try {
      final fullProperty = await PropertyService.getDetails(widget.propertyId);
      if (mounted) {
        setState(() {
          property = fullProperty;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to load property: $e");
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  List<Map<String, dynamic>> getActionButtons(BuildContext context) {
    if (widget.mode == PropertyMode.owned) {
      return [
        {
          'icon': Icons.edit_rounded,
          'label': 'Edit Info',
          'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditPropertyPage(propertyId: widget.propertyId),
              ),
            ).then((_) => _loadProperty());
          }
        },
        {
          'icon': Icons.people_alt_rounded, 
          'label': 'Requests', 
          'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestListPage(propertyId: widget.propertyId),
              ),
            );
          }
        },
        {
          'icon': Icons.list_alt_rounded, 
          'label': 'Listing', 
          'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListingManagementPage(propertyId: widget.propertyId),
              ),
            ).then((_) => _loadProperty());
          }
        },
        {
          'icon': Icons.history_rounded, 
          'label': 'Tenant Record', 
          'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeasePage(propertyId: widget.propertyId),
              ),
            ).then((_) => _loadProperty());
          }},
        {'icon': Icons.report_gmailerrorred_rounded, 'label': 'Issues', 'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IssueListPage(propertyId: widget.propertyId,isOwnerMode: true,),
              ),
            ).then((_) => _loadProperty());
            
        }},
        {'icon': Icons.analytics_rounded, 'label': 'Analytics', 'action': () {}},
      ];
    } else {
      return [
        {'icon': Icons.description_rounded, 'label': 'Contract', 'action': () {}},
        {'icon': Icons.payment_rounded, 'label': 'Pay Rent', 'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PayRentPage(propertyId: widget.propertyId),
              ),
            ).then((_) => _loadProperty());
          }
        },
        {'icon': Icons.chat_bubble_rounded, 'label': 'Chat Owner', 'action': () {}},
        {'icon': Icons.report_rounded, 'label': 'Report Issue', 'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportIssuePage(propertyId: widget.propertyId),
              ),
            ).then((_) => _loadProperty());

        }},
        {'icon': Icons.report_rounded, 'label': 'My Issue', 'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IssueListPage(propertyId: widget.propertyId,isOwnerMode: false,),
              ),
            ).then((_) => _loadProperty());

        }},
      ];
    }
  }

  String _getLocationString() {
    if (property == null) return "";
    final parts = [property!.district, property!.city, property!.state]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? "Location not available" : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (property == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Failed to load property")),
      );
    }

    final buttons = getActionButtons(context);
    final statusColor = AppTheme.getStatusColor(property!.status);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const BackButton(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: (property!.thumbnailUrl != null &&
                        property!.thumbnailUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(ApiService.buildImageUrl(
                            property!.thumbnailUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (property!.thumbnailUrl == null ||
                      property!.thumbnailUrl!.isEmpty)
                  ? Icon(Icons.image, size: 80, color: Colors.grey[500])
                  : null,
            ),

            // Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor, 
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Name
                  Text(
                    property!.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _getLocationString(),
                          style: TextStyle(
                              fontSize: 15, 
                              color: Colors.blueGrey[700],
                              fontWeight: FontWeight.w500
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: statusColor.withOpacity(0.5), width: 1.5),
                    ),
                    child: Text(
                      (property!.status ?? "Unknown").toUpperCase(),
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

            const SizedBox(height: 12),

            // ================= ACTIONS GRID =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12), 
                    child: Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  GridView.builder(
                    // Removed default padding to bring grid closer to text
                    padding: EdgeInsets.zero, 
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12, // Reduced spacing slightly
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95, // Made cards slightly taller
                    ),
                    itemCount: buttons.length,
                    itemBuilder: (context, index) {
                      final btn = buttons[index];
                      return ActionButton(
                        icon: btn['icon'],
                        label: btn['label'],
                        onTap: btn['action'],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}