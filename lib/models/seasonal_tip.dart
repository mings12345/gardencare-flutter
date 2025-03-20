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
      id: json['id'],
      season: json['season'],
      region: json['region'],
      tip: json['tip'],
      plantName: json['plant']['name'],
    );
  }
}