import 'package:flutter/material.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/user_service.dart';
import 'package:flutter_application/custom_widgets/residence_card.dart';
import 'package:flutter_application/pages/property_detail_page.dart';
import 'package:flutter_application/theme.dart';

class MyFavouritePage extends StatefulWidget {
  const MyFavouritePage({super.key});

  @override
  State<MyFavouritePage> createState() => _MyFavouritePageState();
}

class _MyFavouritePageState extends State<MyFavouritePage> {
  List<Residence> _Favourites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the favourites list from the service
      final favourites = await UserService.getUserFavourites();

      if (mounted) {
        setState(() {
          _Favourites = favourites;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading favourites: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleFavouriteToggle(int propertyId, bool isNowFavourited) async {
   
    final success = await UserService.toggleFavourite(propertyId);

    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Removed from favourites"),
        duration: Duration(seconds: 1),
      ),
    );
  }

    _loadFavourites();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No favourites yet",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Favourites"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _Favourites.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: _Favourites.length,
                  itemBuilder: (context, index) {
                    final residence = _Favourites[index];
                    return ResidenceCard(
                      residence: residence,
                      onTap: (id) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailPage(propertyId: id, viewOnly: false,),
                          ),
                        ).then((_) {
                          // Refresh list when returning from details page
                          _loadFavourites();
                        });
                      },
                      onFavoriteToggle: (newValue) =>
                          _handleFavouriteToggle(residence.id, newValue),
                    );
                  },
                ),
    );
  }
}