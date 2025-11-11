enum ResidenceType { house, apartment, villa }

class ResidenceDetail {
  final String id;
  final String title;
  final ResidenceType type;
  final String description;
  final String imageUrl;
  final int rooms;
  final double area;
  final double price;

  ResidenceDetail({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.imageUrl,
    required this.rooms,
    required this.area,
    required this.price,
  });


}
