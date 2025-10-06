class LocationService {
  static const Map<String, Map<String, List<String>>> _locations = {
    "Abu Dhabi": {
      "Abu Dhabi City": [
        "Al Reem Island",
        "Al Mushrif",
        "Khalifa City",
        "Al Bateen",
        "Yas Island",
        "Al Raha Beach",
        "Al Nahyan",
        "Corniche",
        "Al Maryah Island",
        "Mohammed Bin Zayed City"
      ],
      "Al Ain": [
        "Al Jimi",
        "Al Muwaiji",
        "Al Hili",
        "Falaj Hazzaa",
        "Al Towayya",
        "Al Bateen",
        "Zakhir",
        "Al Markhaniya"
      ],
      "Madinat Zayed": [
        "City Center",
        "Al Dhafra",
        "Al Mirfa Road",
        "Liwa Junction"
      ],
      "Ruwais": [
        "Ruwais Housing Complex",
        "Al Ruwais Industrial Area",
        "Ruwais West",
        "Ruwais East"
      ],
      "Ghayathi": [
        "Ghayathi City Center",
        "Western Suburb",
        "Al Sila Road"
      ],
      "Liwa": [
        "Mezaira'a",
        "Hamim",
        "Dhafra Desert",
        "Muzaira'a South"
      ],
      "Mirfa": [
        "Al Mirfa Beach",
        "Mirfa Town Center"
      ],
      "Sila": [
        "Al Sila Center",
        "Al Sila Border Area"
      ]
    },
    "Dubai": {
      "Dubai": [
        "Deira",
        "Bur Dubai",
        "Downtown Dubai",
        "Business Bay",
        "Dubai Marina",
        "Jumeirah",
        "Al Barsha",
        "Al Quoz",
        "Al Nahda",
        "Jumeirah Village Circle",
        "Palm Jumeirah",
        "Dubai Hills",
        "Arabian Ranches",
        "Mirdif"
      ],
      "Hatta": [
        "Hatta Wadi Hub",
        "Hatta Hill Park",
        "Hatta Dam",
        "Hatta Heritage Village"
      ],
      "Al Awir": [
        "Awir Central",
        "Awir Farms Area"
      ],
      "Al Lisaili": [
        "Lisaili Camel Racetrack",
        "Lisaili Village"
      ]
    },
    "Sharjah": {
      "Sharjah": [
        "Al Nahda",
        "Al Majaz",
        "Al Qasimia",
        "Al Taawun",
        "Al Khan",
        "Muwailih",
        "University City",
        "Industrial Area",
        "Al Layyah"
      ],
      "Khor Fakkan": [
        "Khor Fakkan Beach",
        "Shees",
        "Al Haray"
      ],
      "Kalba": [
        "Kalba Corniche",
        "Al Ghail",
        "Khor Kalba Mangrove Area"
      ],
      "Dibba Al-Hisn": [
        "Corniche Road",
        "Central Area"
      ],
      "Al Dhaid": [
        "Al Dhaid City Center",
        "Al Bataeh",
        "Al Madam Road"
      ],
      "Mleiha": [
        "Archaeological Site",
        "Mleiha Town Center"
      ],
      "Al Madam": [
        "Al Madam Central",
        "Old Madam Village"
      ]
    },
    "Ajman": {
      "Ajman": [
        "Al Rashidiya",
        "Al Jurf",
        "Al Nuaimiya",
        "Al Zahra",
        "Al Rawda",
        "Al Mowaihat",
        "Ajman Corniche"
      ],
      "Masfout": [
        "Masfout Town Center",
        "Hatta Border Area"
      ],
      "Manama": [
        "Manama Central",
        "Al Senaiya"
      ]
    },
    "Umm Al Quwain": {
      "Umm Al Quwain": [
        "Al Raas",
        "Al Salama",
        "Al Humrah",
        "Al Ramlah",
        "Old Town",
        "Industrial Area"
      ],
      "Falaj Al Mualla": [
        "Falaj Central",
        "Falaj Farms",
        "Falaj Desert Area"
      ]
    },
    "Ras Al Khaimah": {
      "Ras Al Khaimah": [
        "Al Nakheel",
        "Al Dhait",
        "Al Hamra Village",
        "Mina Al Arab",
        "Julphar Towers",
        "Al Seer",
        "Khuzam",
        "Al Mamourah"
      ],
      "Al Jazirah Al Hamra": [
        "Old Town",
        "New Development Area"
      ],
      "Khatt": [
        "Khatt Springs",
        "Khatt Village"
      ],
      "Sha'am": [
        "Sha'am Center",
        "Sha'am Coastal Area"
      ]
    },
    "Fujairah": {
      "Fujairah": [
        "Al Faseel",
        "Al Gurfa",
        "Sakamkam",
        "Al Hilal",
        "Fujairah Corniche",
        "Dibba Road",
        "Town Center"
      ],
      "Dibba Al-Fujairah": [
        "Dibba Beach",
        "Dibba Corniche",
        "Al Akah"
      ],
      "Masafi": [
        "Masafi Central",
        "Masafi Market"
      ],
      "Qidfa": [
        "Qidfa Village",
        "Qidfa Beach"
      ],
      "Mirbah": [
        "Mirbah Town",
        "Mirbah Beach"
      ]
    }
  };

  static List<String> getEmirates() {
    return _locations.keys.toList()..sort();
  }

  static List<String> getCities(String emirate) {
    if (!_locations.containsKey(emirate)) return [];
    return _locations[emirate]!.keys.toList()..sort();
  }

  static List<String> getAreas(String emirate, String city) {
    if (!_locations.containsKey(emirate)) return [];
    if (!_locations[emirate]!.containsKey(city)) return [];
    return _locations[emirate]![city]!.toList()..sort();
  }

  static bool isValidLocation(String emirate, String city, String area) {
    if (!_locations.containsKey(emirate)) return false;
    if (!_locations[emirate]!.containsKey(city)) return false;
    return _locations[emirate]![city]!.contains(area);
  }
}
