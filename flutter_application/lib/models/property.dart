// Base class
class Property {
  int? id;
  String name;
  String? title;
  String? description;
  String type; // "residence", "vehicle", "item"
  String? thumbnailUrl;
  bool verified;
  String? state;
  String? city;
  String? district;
  String? address;
  double? price;
  String? status; // "listed", "unlisted", "rented"
  String? rules;
  String? features;
  int? ownerId;
  String? ownerName;
  List<String>? gallery;

  Property({
    this.id,
    required this.name,
    this.title,
    this.description,
    required this.type,
    this.thumbnailUrl,
    this.verified = false,
    this.state,
    this.city,
    this.district,
    this.address,
    this.price,
    this.status,
    this.rules,
    this.features,
    this.ownerId,
    this.ownerName,
    this.gallery,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "title": title,
    "description": description,
    "type": type,
    "thumbnail_url": thumbnailUrl,
    "verified": verified,
    "state": state,
    "city": city,
    "district": district,
    "address": address,
    "price": price,
    "status": status,
    "rules": rules,
    "features": features,
    "user_id": ownerId,
    "owner_name": ownerName,
    "gallery": gallery,
  };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      description: json['description'],
      type: json['type'] ?? "general",
      thumbnailUrl: json['thumbnail_url'],
      verified: json['verified'] ?? false,
      state: json['state'],
      city: json['city'],
      district: json['district'],
      address: json['address'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      status: json['status'],
      rules: json['rules'],
      features: json['features'],
      ownerId: json['user_id'],
      ownerName: json['owner_name'],
      gallery: json['gallery'] != null ? List<String>.from(json['gallery']) : null,
    );
  }
}
