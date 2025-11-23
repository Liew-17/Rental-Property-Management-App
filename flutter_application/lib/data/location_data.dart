class LocationData {
  // List of states in Malaysia
  static final List<String> states = [
    "Johor",
    "Kedah",
    "Kelantan",
    "Malacca",
    "Negeri Sembilan",
    "Pahang",
    "Penang",
    "Perak",
    "Perlis",
    "Sabah",
    "Sarawak",
    "Selangor",
    "Terengganu",
    "Kuala Lumpur",
    "Labuan",
    "Putrajaya",
  ];

  // Nested map: State -> District -> List of Cities
  static final Map<String, Map<String, List<String>>> locationData = {
    "Selangor": {
      "Petaling": ["Petaling Jaya", "Subang Jaya", "Klang"],
      "Hulu Langat": ["Kajang", "Semenyih", "Bangi"],
      "Gombak": ["Batu Caves", "Gombak town"],
    },
    "Kuala Lumpur": {
      "Kuala Lumpur": ["Bukit Bintang", "KLCC", "Segambut"],
    },
    "Johor": {
      "Johor Bahru": ["Johor Bahru", "Pasir Gudang", "Kulai"],
      "Muar": ["Muar town", "Tangkak"],
    },
    "Penang": {
      "Seberang Perai": ["Butterworth", "Bukit Mertajam", "Nibong Tebal"],
      "Penang Island": ["George Town", "Bayan Lepas", "Balik Pulau"],
    },
    // Add other states as needed
  };
}
