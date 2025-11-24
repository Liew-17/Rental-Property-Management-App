import 'package:flutter_application/models/property.dart';

class Residence extends Property {
  int? numBedrooms;
  int? numBathrooms;
  double? landSize;

  Residence({
    required super.id,
    required super.name,
    super.title,
    super.description,
    super.thumbnailUrl,
    super.isVerified = false,
    super.state,
    super.city,
    super.district,
    super.address,
    super.price,
    super.status,
    super.rules,
    super.features,
    super.ownerId,
    super.ownerName,
    super.gallery,
    super.isFavorited,
    this.numBedrooms,
    this.numBathrooms,
    this.landSize,
  }) : super(type: "residence");

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      "num_bedrooms": numBedrooms,
      "num_bathrooms": numBathrooms,
      "land_size": landSize,
    });
    return json;
  }

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      isVerified: json['is_verified'] ?? false,
      state: json['state'],
      city: json['city'],
      district: json['district'],
      address: json['address'],
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : 0,
      status: json['status'],
      rules: json['rules'],
      features: json['features'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      gallery: json['gallery'] != null ? List<String>.from(json['gallery']) : [],
      isFavorited: json['is_favorited'] ?? false,
      numBedrooms: json['num_bedrooms'],
      numBathrooms: json['num_bathrooms'],
      landSize: json['land_size'] != null ? (json['land_size'] as num).toDouble() : null,
    );
  }
}
