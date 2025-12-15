import '../models/channel_model.dart';

class CountryInfo {
  final String code;
  final String name;
  final List<String> keywords;
  final List<String> patterns;

  CountryInfo({
    required this.code,
    required this.name,
    required this.keywords,
    required this.patterns,
  });
}

class CountryDetectorService {
  static final List<CountryInfo> _countries = [
    CountryInfo(
      code: 'TR',
      name: 'Türkiye',
      keywords: ['tr', 'tur', 'turkey', 'türkiye', 'türk'],
      patterns: [
        r'\bTR\b',
        r'\bTUR\b',
        r'\bTURKEY\b',
        r'\bTÜRKİYE\b',
        r'\bTÜRK\b',
        r'\bTURK\b',
      ],
    ),
    CountryInfo(
      code: 'DE',
      name: 'Almanya',
      keywords: ['de', 'ger', 'germany', 'deutsch', 'alman'],
      patterns: [
        r'\bDE\b',
        r'\bGER\b',
        r'\bGERMANY\b',
        r'\bDEUTSCH\b',
        r'\bALMAN\b',
      ],
    ),
    CountryInfo(
      code: 'RO',
      name: 'Romanya',
      keywords: ['ro', 'rou', 'romania', 'român', 'roman'],
      patterns: [
        r'\bRO\b',
        r'\bROU\b',
        r'\bROMANIA\b',
        r'\bROMÂN\b',
        r'\bROMAN\b',
      ],
    ),
    CountryInfo(
      code: 'AT',
      name: 'Avusturya',
      keywords: ['at', 'aut', 'austria', 'österr'],
      patterns: [
        r'\bAT\b',
        r'\bAUT\b',
        r'\bAUSTRIA\b',
        r'\bAVUSTURYA\b',
      ],
    ),
    CountryInfo(
      code: 'US',
      name: 'Amerika',
      keywords: ['us', 'usa', 'america', 'american'],
      patterns: [
        r'\bUS\b',
        r'\bUSA\b',
        r'\bAMERICA\b',
        r'\bAMERIKA\b',
      ],
    ),
    CountryInfo(
      code: 'UK',
      name: 'İngiltere',
      keywords: ['uk', 'gb', 'britain', 'english'],
      patterns: [
        r'\bUK\b',
        r'\bGB\b',
        r'\bBRITAIN\b',
        r'\bINGİLTERE\b',
      ],
    ),
    CountryInfo(
      code: 'FR',
      name: 'Fransa',
      keywords: ['fr', 'fra', 'france', 'français'],
      patterns: [
        r'\bFR\b',
        r'\bFRA\b',
        r'\bFRANCE\b',
        r'\bFRANSA\b',
      ],
    ),
    CountryInfo(
      code: 'IT',
      name: 'İtalya',
      keywords: ['it', 'ita', 'italy', 'italia'],
      patterns: [
        r'\bIT\b',
        r'\bITA\b',
        r'\bITALY\b',
        r'\bITALIA\b',
        r'\bİTALYA\b',
      ],
    ),
    CountryInfo(
      code: 'ES',
      name: 'İspanya',
      keywords: ['es', 'esp', 'spain', 'español'],
      patterns: [
        r'\bES\b',
        r'\bESP\b',
        r'\bSPAIN\b',
        r'\bESPAGNE\b',
        r'\bİSPANYA\b',
      ],
    ),
    CountryInfo(
      code: 'NL',
      name: 'Hollanda',
      keywords: ['nl', 'nld', 'netherlands', 'dutch'],
      patterns: [
        r'\bNL\b',
        r'\bNLD\b',
        r'\bNETHERLANDS\b',
        r'\bHOLLANDA\b',
      ],
    ),
    CountryInfo(
      code: 'BE',
      name: 'Belçika',
      keywords: ['be', 'bel', 'belgium', 'belgique'],
      patterns: [
        r'\bBE\b',
        r'\bBEL\b',
        r'\bBELGIUM\b',
        r'\bBELÇIKA\b',
      ],
    ),
    CountryInfo(
      code: 'CH',
      name: 'İsviçre',
      keywords: ['ch', 'che', 'switzerland', 'suisse'],
      patterns: [
        r'\bCH\b',
        r'\bCHE\b',
        r'\bSWITZERLAND\b',
        r'\bİSVİÇRE\b',
      ],
    ),
    CountryInfo(
      code: 'GR',
      name: 'Yunanistan',
      keywords: ['gr', 'gre', 'greece', 'greek'],
      patterns: [
        r'\bGR\b',
        r'\bGRE\b',
        r'\bGREECE\b',
        r'\bYUNANİSTAN\b',
      ],
    ),
    CountryInfo(
      code: 'SE',
      name: 'İsveç',
      keywords: ['se', 'swe', 'sweden', 'svenska'],
      patterns: [
        r'\bSE\b',
        r'\bSWE\b',
        r'\bSWEDEN\b',
        r'\bİSVEÇ\b',
      ],
    ),
    CountryInfo(
      code: 'NO',
      name: 'Norveç',
      keywords: ['no', 'nor', 'norway', 'norsk'],
      patterns: [
        r'\bNO\b',
        r'\bNOR\b',
        r'\bNORWAY\b',
        r'\bNORVEÇ\b',
      ],
    ),
    CountryInfo(
      code: 'DK',
      name: 'Danimarka',
      keywords: ['dk', 'dnk', 'denmark', 'dansk'],
      patterns: [
        r'\bDK\b',
        r'\bDNK\b',
        r'\bDENMARK\b',
        r'\bDANIMARKA\b',
      ],
    ),
    CountryInfo(
      code: 'PL',
      name: 'Polonya',
      keywords: ['pl', 'pol', 'poland', 'polska'],
      patterns: [
        r'\bPL\b',
        r'\bPOL\b',
        r'\bPOLAND\b',
        r'\bPOLSKA\b',
        r'\bPOLONYA\b',
      ],
    ),
    CountryInfo(
      code: 'CZ',
      name: 'Çekya',
      keywords: ['cz', 'cze', 'czech', 'česko'],
      patterns: [
        r'\bCZ\b',
        r'\bCZE\b',
        r'\bCZECH\b',
        r'\bÇEKYA\b',
      ],
    ),
    CountryInfo(
      code: 'SK',
      name: 'Slovakya',
      keywords: ['sk', 'svk', 'slovakia', 'slovensko'],
      patterns: [
        r'\bSK\b',
        r'\bSVK\b',
        r'\bSLOVAKIA\b',
        r'\bSLOVAKYA\b',
      ],
    ),
    CountryInfo(
      code: 'HU',
      name: 'Macaristan',
      keywords: ['hu', 'hun', 'hungary', 'magyar'],
      patterns: [
        r'\bHU\b',
        r'\bHUN\b',
        r'\bHUNGARY\b',
        r'\bMACARISTAN\b',
      ],
    ),
  ];

  // Get all available countries
  static List<CountryInfo> getAllCountries() {
    return List.from(_countries);
  }

  // Get country by code
  static CountryInfo? getCountryByCode(String code) {
    try {
      return _countries.firstWhere((country) =>
        country.code.toUpperCase() == code.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  // Detect country from channel name or group
  static CountryInfo? detectCountry(String text) {
    if (text.isEmpty) return null;

    final cleanText = text.toLowerCase().trim();

    // First, try exact pattern matches (more reliable)
    for (final country in _countries) {
      for (final pattern in country.patterns) {
        try {
          final regex = RegExp(pattern, caseSensitive: false);
          if (regex.hasMatch(text)) {
            return country;
          }
        } catch (e) {
          // Continue if regex fails
        }
      }
    }

    // Then, try keyword matching
    for (final country in _countries) {
      for (final keyword in country.keywords) {
        if (cleanText.contains(keyword.toLowerCase())) {
          return country;
        }
      }
    }

    return null;
  }

  // Filter channels by selected countries
  static List<ChannelModel> filterChannelsByCountries(
    List<ChannelModel> channels,
    List<String> countryCodes, {
    bool includeUnknown = false,
  }) {
    if (countryCodes.isEmpty && !includeUnknown) {
      return [];
    }

    final filteredChannels = <ChannelModel>[];

    for (final channel in channels) {
      // Check group title
      final groupCountry = detectCountry(channel.groupTitle);

      // Check channel name if group doesn't have a country
      final nameCountry = groupCountry ?? detectCountry(channel.name);

      final detectedCountry = nameCountry;

      if (detectedCountry != null) {
        if (countryCodes.contains(detectedCountry.code)) {
          filteredChannels.add(channel);
        }
      } else if (includeUnknown) {
        // Include channels with unknown country
        filteredChannels.add(channel);
      }
    }

    return filteredChannels;
  }

  // Get channel groups organized by country
  static Map<String?, List<String>> getGroupsByCountry(
    List<ChannelModel> channels,
  ) {
    final groupsByCountry = <String?, List<String>>{};

    // Get unique groups
    final uniqueGroups = channels
        .map((c) => c.groupTitle)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();

    for (final group in uniqueGroups) {
      final country = detectCountry(group);
      final countryCode = country?.code ?? 'UNKNOWN';

      if (!groupsByCountry.containsKey(countryCode)) {
        groupsByCountry[countryCode] = [];
      }

      groupsByCountry[countryCode]!.add(group);
    }

    // Sort groups within each country
    for (final groups in groupsByCountry.values) {
      groups.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    return groupsByCountry;
  }

  // Get statistics about countries in playlist
  static Map<String, int> getCountryStatistics(List<ChannelModel> channels) {
    final stats = <String, int>{};

    for (final channel in channels) {
      final country = detectCountry(channel.groupTitle) ??
                     detectCountry(channel.name);

      final countryCode = country?.code ?? 'UNKNOWN';

      stats[countryCode] = (stats[countryCode] ?? 0) + 1;
    }

    // Sort by count (descending)
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  // Check if text contains any of the selected country keywords
  static bool containsSelectedCountry(String text, List<String> countryCodes) {
    final country = detectCountry(text);
    return country != null && countryCodes.contains(country.code);
  }

  // Get default selected countries
  static List<String> getDefaultCountries() {
    return ['TR', 'DE', 'RO', 'AT'];
  }

  // Validate country code
  static bool isValidCountryCode(String code) {
    return _countries.any((country) =>
      country.code.toUpperCase() == code.toUpperCase());
  }

  // Search countries by name
  static List<CountryInfo> searchCountries(String query) {
    if (query.isEmpty) return _countries;

    final lowerQuery = query.toLowerCase();
    return _countries.where((country) =>
      country.name.toLowerCase().contains(lowerQuery) ||
      country.code.toLowerCase().contains(lowerQuery) ||
      country.keywords.any((keyword) => keyword.contains(lowerQuery))
    ).toList();
  }

  // Get country info from channel
  static CountryInfo? getChannelCountry(ChannelModel channel) {
    return detectCountry(channel.groupTitle) ??
           detectCountry(channel.name);
  }

  // Filter groups by selected countries
  static List<String> filterGroupsByCountries(
    List<String> groups,
    List<String> countryCodes,
  ) {
    return groups.where((group) {
      final country = detectCountry(group);
      return country != null && countryCodes.contains(country.code);
    }).toList();
  }
}