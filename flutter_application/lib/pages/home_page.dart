import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/residence_card.dart';
import 'package:flutter_application/custom_widgets/location_header.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/property_detail_page.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/services/user_service.dart';
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
  int totalPages = 1; 
  final int pageSize = 10;
  bool _isLoading = false;

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

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    } 

    List<Residence> data = await loadNearbyResidences(page: page);

    if (!mounted) return;

    setState(() {
      nearByResidences = data;
      currentPage = page;
      _isLoading = false;
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

      totalPages = (result.totalCount / pageSize).ceil(); 

      return result.residences;
    } catch (e) {
      debugPrint("Failed to load nearby residences: $e");
      totalPages = 0;
      return []; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16,),
                LocationHeader(
                  onChanged: () {
                      _loadPage(1); 
                  }
                ),
                
                // Search Bar
                Padding(
                  
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: Material(
                    color: Colors.grey[200], 
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.grey.withOpacity(0.3),
                      highlightColor: Colors.grey.withOpacity(0.1),
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

                for (var residence in nearByResidences) ...[
                  ResidenceCard(
                    residence: residence,
                    onTap: (id) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PropertyDetailPage(propertyId: id, viewOnly: false),
                        ),
                      );
                    },
                    onFavoriteToggle: (newValue) {
                      setState(() {
                        residence.isFavourited = newValue;
                        UserService.toggleFavourite(residence.id);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (totalPages > 1) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: currentPage > 1
                            ? () => _loadPage(currentPage - 1)
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Prev"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          disabledForegroundColor: Colors.grey[300],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        "Page $currentPage of $totalPages",
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(width: 12),

                      TextButton.icon(
                        onPressed: currentPage < totalPages
                            ? () => _loadPage(currentPage + 1)
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("Next"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          disabledForegroundColor: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }
}