import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/filter_widget.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/custom_widgets/residence_card.dart';
import 'package:flutter_application/pages/property_detail_page.dart';
import 'package:flutter_application/services/user_service.dart';
import 'package:flutter_application/theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // State
  List<Residence> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Filters
  Map<String, dynamic> _filters = {};

  void _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await PropertyService.searchResidences(
      query: _searchController.text,
      state: _filters['state'],
      city: _filters['city'],
      district: _filters['district'],
      minPrice: _filters['minPrice'],
      maxPrice: _filters['maxPrice'],
      residenceType: _filters['residenceType'],
      minBedrooms: _filters['minBedrooms'],
      minBathrooms: _filters['minBathrooms'],
      minSize: _filters['minSize'],
      maxSize: _filters['maxSize'],
    );

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  void _openFilter() async {
    final newFilters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterSheet(currentFilters: _filters),
    );

    if (newFilters != null) {
      setState(() {
        _filters = newFilters;
      });
      // Auto-search when filters are applied
      _performSearch();
    }
  }

  void _onCardTap(int id) {
     Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PropertyDetailPage(propertyId: id, viewOnly: false,)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search properties...',
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter Button
                  IconButton(
                    icon: Icon(Icons.tune, 
                      color: _filters.isNotEmpty ? AppTheme.primaryColor : Colors.grey[600]
                    ),
                    onPressed: _openFilter,
                    tooltip: "Filters",
                  ),
                  // Search Button
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white, size: 20),
                      onPressed: _performSearch,
                    ),
                  ),
                ],
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Find your perfect home",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No properties found matching your criteria",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            TextButton(
              onPressed: _openFilter,
              child: const Text("Adjust Filters"),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return Center(
          child: ResidenceCard(
            residence: _results[index],
            onTap: _onCardTap,
              onFavoriteToggle: (newValue) {
                      setState(() {
                        _results[index].isFavourited = newValue;
                        UserService.toggleFavourite(_results[index].id);
                      });
                    },
          ),
        );
      },
    );
  }
}