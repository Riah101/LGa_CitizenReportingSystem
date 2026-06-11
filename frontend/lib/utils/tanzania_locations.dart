/// Tanzania Administrative Hierarchy Data
/// Mkoa → Wilaya → Kata → Mtaa
library;

class TanzaniaLocations {
  static const Map<String, Map<String, List<String>>> hierarchy = {
    'Dar es Salaam': {
      'Ilala': [
        'Kariakoo', 'Gerezani', 'Kisutu', 'Kivukoni', 'Mchafukoge',
        'Upanga Magharibi', 'Upanga Mashariki', 'Ilala', 'Buguruni',
        'Charambe', 'Jangwani', 'Kipawa', 'Kitunda', 'Msongola',
        'Segerea', 'Tabata', 'Ukonga',
      ],
      'Kinondoni': [
        'Mwananyamala', 'Mikocheni', 'Kinondoni', 'Magomeni', 'Makurumla',
        'Hananasifu', 'Kigogo', 'Korogwe', 'Manzese', 'Msasani',
        'Ndugumbi', 'Sinza', 'Tandale', 'Wazo',
      ],
      'Temeke': [
        'Temeke', 'Miburani', 'Mtoni', 'Kigamboni', 'Chamazi',
        'Chang\'ombe', 'Kurasini', 'Mbagala', 'Sandali', 'Toangoma',
        'Vijibweni', 'Yombo Vituka',
      ],
      'Ubungo': [
        'Ubungo', 'Kimara', 'Kibamba', 'Makuburi', 'Makoka',
        'Kwembe', 'Sandali',
      ],
      'Kigamboni': [
        'Kigamboni', 'Kibada', 'Kisarawe II', 'Pembamnazi', 'Somangira',
        'Tuamoyo', 'Mjimwema',
      ],
    },
    'Arusha': {
      'Arusha City': [
        'Elerai', 'Engutoto', 'Kaloleni', 'Kimandolu', 'Kware',
        'Levolosi', 'Moshono', 'Muriet', 'Oloirien', 'Sekei',
        'Sombetini', 'Themi', 'Tololwa',
      ],
      'Arumeru': [
        'Maji ya Chai', 'Meru', 'Nkoanrua', 'Nkoaranga', 'Tengeru',
        'Usa River',
      ],
      'Monduli': ['Monduli', 'Engare Nanyuki', 'Lolkisale', 'Makuyuni'],
    },
    'Mwanza': {
      'Nyamagana': [
        'Bugando', 'Igogo', 'Isamilo', 'Kirumba', 'Kitangiri',
        'Mahina', 'Mbugani', 'Mirongo', 'Nyakato', 'Nyamanoro',
      ],
      'Ilemela': [
        'Buhongwa', 'Igoma', 'Ilemela', 'Kayenze', 'Kiroba',
        'Luchelele', 'Mkolani', 'Nyabohu', 'Sangabuye',
      ],
    },
    'Dodoma': {
      'Dodoma Urban': [
        'Dodoma Makulu', 'Chamwino', 'Ipagala', 'Kikuyu', 'Kilimani',
        'Kisasa', 'Makole', 'Mapinduzi', 'Msalato', 'Nzuguni',
      ],
      'Chamwino': ['Buigiri', 'Chamwino', 'Idifu', 'Ikowa', 'Manchali'],
    },
    'Morogoro': {
      'Morogoro Urban': [
        'Bonde la Mpunga', 'Chamwino', 'Kihonda', 'Kilakala',
        'Mawenzi', 'Mazimbu', 'Mji Mkuu', 'Mzinga',
      ],
      'Kilosa': ['Kilosa', 'Gairo', 'Kimamba', 'Mikumi', 'Rudewa'],
    },
    'Zanzibar': {
      'Mjini': ['Mji Mkongwe', 'Kikwajuni', 'Mlandege', 'Shaurimoyo'],
      'Kaskazini Unguja': ['Matemwe', 'Mkokotoni', 'Nungwi', 'Donge'],
      'Kusini Unguja': ['Kizimkazi', 'Koani', 'Makunduchi'],
    },
  };

  static List<String> get regions => hierarchy.keys.toList()..sort();

  static List<String> districtsForRegion(String region) =>
      hierarchy[region]?.keys.toList() ?? [];

  static List<String> wardsForDistrict(String region, String district) =>
      hierarchy[region]?[district] ?? [];

  /// All wards in Kinondoni district — the only scope of this app.
  static List<String> get kinondoniWards =>
      hierarchy['Dar es Salaam']!['Kinondoni']!;
}
