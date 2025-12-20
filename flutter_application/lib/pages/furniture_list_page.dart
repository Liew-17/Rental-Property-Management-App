import 'package:flutter/material.dart';
import 'package:flutter_application/models/furniture.dart';
import 'package:flutter_application/pages/add_furniture_page.dart';
import 'package:flutter_application/pages/furniture_details_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/furniture_service.dart';
import 'package:flutter_application/theme.dart';

class FurnitureListPage extends StatefulWidget {
  final int propertyId;

  const FurnitureListPage({super.key, required this.propertyId});

  @override
  State<FurnitureListPage> createState() => _FurnitureListPageState();
}

class _FurnitureListPageState extends State<FurnitureListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Lists for each status category
  List<Furniture> _goodFurniture = [];
  List<Furniture> _damagedFurniture = [];
  List<Furniture> _repairedFurniture = [];
  List<Furniture> _disposedFurniture = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFurniture();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFurniture() async {
    setState(() => _isLoading = true);
    try {

      final furnitureList = await FurnitureService.getFurnitureByProperty(widget.propertyId);
      
      if (mounted) {
        setState(() {
          // Categorize items by status
          _goodFurniture = furnitureList.where((f) => f.status == 'Good').toList();
          _damagedFurniture = furnitureList.where((f) => f.status == 'Damaged').toList();
          _repairedFurniture = furnitureList.where((f) => f.status == 'Repaired').toList();
          _disposedFurniture = furnitureList.where((f) => f.status == 'Disposed').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading furniture: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper for Status Colors (Local override since AppTheme might not have these specific keys)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Good': return Colors.green;
      case 'Damaged': return Colors.red;
      case 'Repaired': return Colors.orange;
      case 'Disposed': return Colors.grey;
      default: return AppTheme.primaryColor;
    }
  }

  Widget _buildFurnitureList(List<Furniture> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chair_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("No items found", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFurniture,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FurnitureDetailPage(furnitureId: item.id),
                  ),
                ).then((_) => _loadFurniture());
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Thumbnail Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(ApiService.buildImageUrl(item.imageUrl!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.imageUrl == null || item.imageUrl!.isEmpty
                          ? const Icon(Icons.image_not_supported, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Info Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(item.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.status,
                              style: TextStyle(
                                color: _getStatusColor(item.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (item.note != null && item.note!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text("Furniture Inventory", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Good"),
            Tab(text: "Damaged"),
            Tab(text: "Repaired"),
            Tab(text: "Disposed"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFurnitureList(_goodFurniture),
                _buildFurnitureList(_damagedFurniture),
                _buildFurnitureList(_repairedFurniture),
                _buildFurnitureList(_disposedFurniture),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () async {

          Navigator.push(
            context,
          MaterialPageRoute(builder: (_) => AddFurniturePage(propertyId: widget.propertyId)),
         ).then((_) => _loadFurniture());
         
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}