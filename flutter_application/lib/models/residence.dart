import 'package:flutter_application/models/property.dart';

class Residence extends Property {
  int? numBedrooms;
  int? numBathrooms;
  double? landSize;
  String? residenceType;

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
    super.deposit, 
    super.status,
    super.rules,
    super.features,
    super.ownerId,
    super.ownerName,
    super.ownerPicUrl, 
    super.gallery,
    super.isFavourited,
    this.numBedrooms,
    this.numBathrooms,
    this.landSize,
    this.residenceType,
  }) : super(type: "residence");

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      "num_bedrooms": numBedrooms,
      "num_bathrooms": numBathrooms,
      "land_size": landSize,
      "residence_type": residenceType,
      "deposit": deposit, 
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
      deposit: (json['deposit'] != null) ? (json['deposit'] as num).toDouble() : 0,
      status: json['status'],
      rules: json['rules'],
      features: json['features'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      ownerPicUrl: json['owner_pic_url'], 
      gallery: json['gallery'] != null ? List<String>.from(json['gallery']) : [],
      isFavourited: json['is_favourited'] ?? false,
      numBedrooms: json['num_bedrooms'],
      numBathrooms: json['num_bathrooms'],
      landSize: json['land_size'] != null ? (json['land_size'] as num).toDouble() : null,
      residenceType: json['residence_type'],
    );
  }
}