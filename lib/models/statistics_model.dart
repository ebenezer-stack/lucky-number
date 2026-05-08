class NumberStatistics {
  final int number;
  final int frequency;
  final double percentage;
  final DateTime lastDrawn;

  NumberStatistics({
    required this.number,
    required this.frequency,
    required this.percentage,
    required this.lastDrawn,
  });

  factory NumberStatistics.fromMap(Map<String, dynamic> map) {
    return NumberStatistics(
      number: map['number'] as int,
      frequency: map['frequency'] as int,
      percentage: map['percentage'] as double,
      lastDrawn: DateTime.parse(map['last_drawn'] as String),
    );
  }
}
