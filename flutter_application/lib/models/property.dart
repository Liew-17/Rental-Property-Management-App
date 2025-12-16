class Property {
  int id;
  String name;
  String? title;
  String? description;
  String type;
  String? thumbnailUrl;
  bool isVerified;
  String? state;
  String? city;
  String? district;
  String? address;
  double? price;
  double? deposit; 
  String? status; 
  String? rules;
  String? features;
  int? ownerId;
  String? ownerName;
  String? ownerPicUrl; // <--- Add this
  List<String>? gallery;
  bool isFavourited;

  Property({
    required this.id,
    required this.name,
    this.title,
    this.description,
    required this.type,
    this.thumbnailUrl,
    this.isVerified = false,
    this.state,
    this.city,
    this.district,
    this.address,
    this.price,
    this.deposit, 
    this.status,
    this.rules,
    this.features,
    this.ownerId,
    this.ownerName,
    this.ownerPicUrl, 
    this.gallery,
    this.isFavourited = false,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "title": title,
    "description": description,
    "type": type,
    "thumbnail_url": thumbnailUrl,
    "is_verified": isVerified,
    "state": state,
    "city": city,
    "district": district,
    "address": address,
    "price": price,
    "deposit": deposit,
    "status": status,
    "rules": rules,
    "features": features,
    "owner_id": ownerId,
    "owner_name": ownerName,
    "owner_pic_url": ownerPicUrl, 
    "gallery": gallery,
    "is_favorited": isFavourited,
  };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      description: json['description'],
      type: json['type'] ?? "general",
      thumbnailUrl: json['thumbnail_url'],
      isVerified: json['is_verified'] ?? false,
      state: json['state'],
      city: json['city'],
      district: json['district'],
      address: json['address'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0,
      deposit: json['deposit'] != null ? (json['deposit'] as num).toDouble() : 0,
      status: json['status'],
      rules: json['rules'],
      features: json['features'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      ownerPicUrl: json['owner_pic_url'], 
      gallery: json['gallery'] != null ? List<String>.from(json['gallery']) : null,
      isFavourited: json['is_favourited'] ?? false,
    );
  }
}