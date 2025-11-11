class ResidenceSummary {
  final String id;
  final String title;
  final String? imageUrl; 
  final int numBeds;
  final int numBaths;
  final int area;
  final double price;      
  bool isFavorited;

  ResidenceSummary({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.numBeds,
    required this.numBaths,
    required this.area,
    required this.price,
    required this.isFavorited,
  });

  factory ResidenceSummary.fromJson(Map<String, dynamic> json) {
    return ResidenceSummary(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      numBeds: json['numBeds'] ?? 0,
      numBaths: json['numBaths'] ?? 0,
      area: json['area'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      isFavorited: json['isFavorited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'numBeds': numBeds,
      'numBaths': numBaths,
      'area': area,
      'price': price,
      'isFavorited': isFavorited,
    };
  }
}
