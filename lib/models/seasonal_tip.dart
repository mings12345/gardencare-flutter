class SeasonalTip {
  final int id;
  final String season;
  final String region;
  final String tip;
  final String plantName;

  SeasonalTip({
    required this.id,
    required this.season,
    required this.region,
    required this.tip,
    required this.plantName,
  });

  factory SeasonalTip.fromJson(Map<String, dynamic> json) {
    return SeasonalTip(
      id: json['id'] ?? 0,
      season: json['season'] ?? 'Unknown Season',
      region: json['region'] ?? 'Unknown Region',
      tip: json['tip'] ?? 'No tip available',
      plantName: json['plant']?['name'] ?? 'Unknown Plant', // ✅ Fix: Prevents null error
    );
  }
}
