class LocationData {
  // States from your dataset (STATE MEANS)
  static final List<String> states = [
    "Johor",
    "Kedah",
    "Kelantan",
    "Kuala Lumpur",
    "Melaka",
    "Negeri Sembilan",
    "Pahang",
    "Penang",
    "Perak",
    "Putrajaya",
    "Sabah",
    "Sarawak",
    "Selangor"
  ];

  // Nested map: State -> District -> List of Towns/Cities (from your TOWN MEANS)
  static final Map<String, Map<String, List<String>>> locationData = {
    "Johor": {
      "Johor Bahru": [
        "Bandar Johor Bahru",
        "Tebrau",
        "Pulai",
        "Kulai",
        "Plentong",
        "Kapar" 
      ],
      "Kulaijaya": ["Kulai"],
      "Muar": ["Muar town", "Tangkak"],
      "Tangkak": ["Tangkak"],
      "Kulaijaya (alternate)": ["Labu"] 
    },
    "Kedah": {
      "Kuala Muda": ["Sungai Petani"],
      "Pendang": ["Pendang"],
      "Langkawi": ["Padang Masirat"]
    },
    "Kelantan": {
      "Kota Bharu": ["Kota Bharu", "Panji", "Tanjong Keling"],
      "Bentong": ["Bentong"] 
    },
    "Kuala Lumpur": {
      "Kuala Lumpur": [
        "Bandar Kuala Lumpur",
        "Kuala Lumpur",
        "Setapak",
        "Bukit Bintang" 
      ]
    },
    "Melaka": {
      "Melaka Tengah Central Malacca": [
        "Bukit Baru",
        "Bukit Rambai",
        "Bukit Raya",
        "Melaka town"
      ],
      "Alor Gajah": ["Rembau"] 
    },
    "Negeri Sembilan": {
      "Seremban": ["Bandar Seremban", "Rasah", "Labu"]
    },
    "Pahang": {
      "Kuantan": ["Kuala Kuantan"],
      "Bentong": ["Bentong"]
    },
    "Penang": {
  
      "Barat Daya Southwest Penang": [
        "Mukim 10",
        "Mukim 11",
        "Bukit Balik Pulau",
        "Bayan Lepas",
        "Pondok Upeh",
        "Telok Kumbar"
      ],
      "Timur Laut Northeast Penang": [
        "Bandaraya Georgetown",
        "Mukim 13",
        "Mukim 14",
        "Mukim 15",
        "Paya Terubong"
      ],
      "Central Seberang Perai": [
        "-"
      ]
    },
    "Perak": {
      "Kinta": ["Ulu Kinta", "Kinta"],
      "Ulu Kinta": ["Ulu Kinta"]
    },
    "Putrajaya": {
      "Putrajaya": ["Putrajaya"]
    },
    "Sabah": {
      "Kota Kinabalu": ["Kota Kinabalu"],
      "Putatan": ["Putatan"],
      "Tuaran": ["Tuaran"],
      "Pondok Upeh (alt)": ["Pondok Upeh"] 
    },
    "Sarawak": {
      "Kuching": ["Kuching"],
      "Sibu": ["Sibu"]
    },
    "Selangor": {
      "Petaling": ["Petaling Jaya", "Petaling"],
      "Hulu Langat": ["Kajang", "Semenyih", "Ulu Langat"],
      "Gombak": ["Batu", "Gombak"],
      "Klang": ["Bandar Klang", "Klang", "Bukit Raja", "Telok Panglima Garang", "Kapar", "Bandar Klang"],
      "Kuala Selangor": ["Kuala Selangor", "Ulu Selangor"],
      "Sepang": ["Sepang"],
      "Damansara": ["Damansara"],
      "Rawang": ["Rawang"],
      "Sungai Buloh": ["Sungai Buloh"],
      "Ulu Klang": ["Ulu Klang"]
    },
  };
}