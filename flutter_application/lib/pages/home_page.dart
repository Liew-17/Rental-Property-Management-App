import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/residence_card.dart';
import 'package:flutter_application/models/residence_summary.dart';
import 'package:flutter_application/pages/property_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  var exampleResidence = ResidenceSummary( id: '1', title: 'Luxury Apartment', imageUrl: null, numBeds: 3, numBaths: 2, area: 1200, price: 350000, isFavorited: false, );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home1')),
      body: Center(
         child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false, 
            overscroll: false,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 //search bar 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/search');
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        filled: true, 
                        fillColor: Colors.grey[200],
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

                ResidenceCard(
                  residence: exampleResidence,
                  onTap: (id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped residence id: $id')),
                    );
                  },
                  onFavoriteToggle: (newValue) {
                    setState(() {
                      exampleResidence.isFavorited = newValue;
                    });
                    debugPrint('Favorite changed: $newValue');
                  },
                ),
                const SizedBox(height: 16),
                ResidenceCard(
                  residence: exampleResidence,
                  onTap: (id) {
                        Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailPage(residence: exampleResidence),
                      ),
                    );
                  },
                  onFavoriteToggle: (newValue) {
                    setState(() {
                      exampleResidence.isFavorited = newValue;
                    });
                    debugPrint('Favorite changed: $newValue');
                  },
                ),
                const SizedBox(height: 16),
                ResidenceCard(
                  residence: exampleResidence,
                  onTap: (id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped residence id: $id')),
                    );
                  },
                  onFavoriteToggle: (newValue) {
                    setState(() {
                      exampleResidence.isFavorited = newValue;
                    });
                    debugPrint('Favorite changed: $newValue');
                  },
                ),
              ],
            ),
          ),
        ),
      
      
      )
    );
  }
}
