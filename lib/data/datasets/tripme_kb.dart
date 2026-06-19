class TripMeKb {
  static const List<Map<String, dynamic>> destinations = [
    {
      "name": "Colombo",
      "must_see": ["Gangaramaya Temple", "Lotus Tower", "Galle Face Green", "National Museum"],
      "indoor": ["National Museum", "Dutch Hospital Shopping Precinct", "One Galle Face Mall"],
      "costs": {"meal": "800-2500", "tuk": "100-500", "hotel": "5000-25000"},
      "safety": "Be aware of three-wheeler scams; use PickMe or Uber. Respect religious sites.",
    },
    {
      "name": "Kandy",
      "must_see": ["Temple of the Tooth", "Royal Botanical Gardens", "Kandy Lake", "Bahirawakanda Buddha"],
      "indoor": ["Temple of the Tooth Museum", "World Buddhist Museum", "Kandy City Centre"],
      "costs": {"meal": "600-2000", "tuk": "200-800", "hotel": "4000-20000"},
      "safety": "Monkeys near the lake can be aggressive. Dress modestly for the Temple.",
    },
    {
      "name": "Ella",
      "must_see": ["Nine Arch Bridge", "Little Adam's Peak", "Ella Rock", "Ravana Falls"],
      "indoor": ["Spice Garden tours", "Cooking classes"],
      "costs": {"meal": "700-2500", "tuk": "300-1000", "hotel": "3500-18000"},
      "safety": "Leaches on Ella Rock trail after rain. Be careful near the bridge edges.",
    },
    {
      "name": "Galle",
      "must_see": ["Galle Fort", "Lighthouse", "Dutch Reformed Church", "Maritime Museum"],
      "indoor": ["Maritime Museum", "Galle Fort boutiques", "Old Dutch Hospital"],
      "costs": {"meal": "1000-3500", "tuk": "200-700", "hotel": "6000-35000"},
      "safety": "Ocean currents can be strong near the fort walls. Negotiate tuk-tuk prices.",
    },
    {
      "name": "Sigiriya",
      "must_see": ["Lion Rock", "Pidurangala Rock", "Sigiriya Museum"],
      "indoor": ["Sigiriya Museum"],
      "costs": {"meal": "800-2000", "tuk": "300-1200", "hotel": "5000-25000"},
      "safety": "Wasps on Lion Rock; follow silence rules. Climb early to avoid heat.",
    },
    {
      "name": "Nuwara Eliya",
      "must_see": ["Gregory Lake", "Victoria Park", "Pedro Tea Estate", "Horton Plains"],
      "indoor": ["Tea Factory visits", "Grand Hotel high tea"],
      "costs": {"meal": "700-2500", "tuk": "200-800", "hotel": "5000-30000"},
      "safety": "Temperature drops significantly at night. Mist on Horton Plains can be disorienting.",
    },
    {
      "name": "Mirissa",
      "must_see": ["Mirissa Beach", "Coconut Tree Hill", "Parrot Rock", "Whale Watching"],
      "indoor": ["Surfing schools (limited)", "Spa/Wellness centers"],
      "costs": {"meal": "900-3000", "tuk": "200-600", "hotel": "4500-22000"},
      "safety": "Be cautious of strong waves. Only use licensed whale watching operators.",
    },
    {
      "name": "Jaffna",
      "must_see": ["Nallur Kandaswamy Kovil", "Jaffna Fort", "Casuarina Beach", "Nagadeepa Temple"],
      "indoor": ["Jaffna Public Library (limited access)", "Archaeological Museum"],
      "costs": {"meal": "500-1500", "tuk": "100-500", "hotel": "3000-15000"},
      "safety": "Respect deeply religious and conservative culture. Some areas still restricted.",
    },
    {
      "name": "Trincomalee",
      "must_see": ["Koneswaram Temple", "Nilaveli Beach", "Pigeon Island", "Fort Frederick"],
      "indoor": ["Maritime Museum"],
      "costs": {"meal": "700-2200", "tuk": "200-800", "hotel": "4000-20000"},
      "safety": "Strong currents at Nilaveli. Deer in Fort Frederick are wild; don't feed them.",
    },
    {
      "name": "Bentota",
      "must_see": ["Bentota Beach", "Madhu River Safari", "Brief Garden", "Kosgoda Turtle Hatchery"],
      "indoor": ["Ayurvedic spas", "Jeffery Bawa's Lunuganga (tours)"],
      "costs": {"meal": "1000-4000", "tuk": "300-900", "hotel": "7000-40000"},
      "safety": "Avoid unauthorized 'guides' on the beach.",
    },
  ];

  static const Map<String, dynamic> transport = {
    "train": "Scenic, affordable, but requires booking (especially Kandy/Ella). 1st class: 2000-5000, 2nd: 800-1500, 3rd: 300-600.",
    "bus": "Normal (very cheap), Semi-Luxury (crowded), Highway AC (comfortable, limited routes).",
    "tuk": "Maximum flexibility. Always agree on price first or use apps. ~100-150 LKR per km.",
    "car": "Private driver is safest and most comfortable for families/groups. ~15,000-25,000 LKR per day.",
  };

  static const Map<String, dynamic> generalTips = {
    "weather": "Monsoon varies by region. SW Monsoon (May-Sep), NE Monsoon (Dec-Feb).",
    "etiquette": "Cover shoulders and knees in temples. Remove shoes/hats. Don't pose with back to Buddha statues.",
    "water": "Drink bottled or filtered water only.",
    "money": "Cash is king in small towns. Use bank ATMs for best rates.",
  };
}
