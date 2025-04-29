class Plant {
  final int id;
  final String name;
  final String wateringFrequency;
  final String sunlight;
  final String soil;
  final String fertilizer;
  final String commonProblems;

  Plant({
    required this.id,
    required this.name,
    required this.wateringFrequency,
    required this.sunlight,
    required this.soil,
    required this.fertilizer,
    required this.commonProblems,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'],
      name: json['name'],
      wateringFrequency: json['watering_frequency'],
      sunlight: json['sunlight'],
      soil: json['soil'],
      fertilizer: json['fertilizer'],
      commonProblems: json['common_problems'],
    );
  }
}
