import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/residence_card.dart';
import 'package:flutter_application/custom_widgets/location_header.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/property_detail_page.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  List<Residence> nearByResidences = [];
  int currentPage = 1;
  int totalPages = 1; // Update this after API call
  final int pageSize = 10;

  Future<void> _loadPage(int page) async {

    if (_scrollController.hasClients) { // safe check
    _scrollController.jumpTo(0);
    } 

    List<Residence> data = await loadNearbyResidences(page: page);

    if (!mounted) return; // prevent dispose issue

    setState(() {
      nearByResidences = data;
      currentPage = page;
    });



  }

  Future<List<Residence>> loadNearbyResidences({required int page}) async {
    final user = AppUser();
    final state = user.state;
    final city = user.city;
    final district = user.district;

    try {
      final result = await PropertyService.query(
        state: state,
        city: city,
        district: district,
        page: page,
      );

      totalPages = (result.totalCount / pageSize).ceil(); //set total page

      return result.residences;
    } catch (e) {
      debugPrint("Failed to load nearby residences: $e");
      totalPages = 0;
      return []; // return empty list on failure
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPage(currentPage);
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocationHeader(
              onChanged: () {
                  _loadPage(1); // Reload page when location changed
              }
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                color: Colors.grey[200], 
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.grey.withValues(alpha: 0.3), // Ripple color
                  highlightColor: Colors.grey.withValues(alpha: 0.1), // Press color
                  onTap: () {
                    Navigator.pushNamed(context, '/search');
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Residence card
            for (var residence in nearByResidences) ...[
              ResidenceCard(
                residence: residence,
                onTap: (id) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PropertyDetailPage(propertyId: id,viewOnly: false),
                    ),
                  );
                },
                onFavoriteToggle: (newValue) {
                  setState(() {
                    residence.isFavorited = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 20),

            // Page control

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Prev button
                TextButton.icon(
                  onPressed: currentPage > 1
                      ? () => _loadPage(currentPage - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Prev"),
                  style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,  
                  )
                ),

                const SizedBox(width: 12),

                // Page number display
                Text(
                  "Page $currentPage of $totalPages",
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(width: 12),

                // Next button
                TextButton.icon(
                  onPressed: currentPage != totalPages
                      ? () => _loadPage(currentPage + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Next"),
                  style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,  
                  )
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
