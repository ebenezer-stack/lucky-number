class Draw {
  final int? id;
  final List<int> winningNumbers;
  final String mode;
  final int winnersCount;
  final DateTime date;
  final int minRange;
  final int maxRange;
  final bool allowDuplicates;

  Draw({
    this.id,
    required this.winningNumbers,
    required this.mode,
    required this.winnersCount,
    required this.date,
    required this.minRange,
    required this.maxRange,
    required this.allowDuplicates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'winning_numbers': winningNumbers.join(','),
      'mode': mode,
      'winners_count': winnersCount,
      'date': date.toIso8601String(),
      'min_range': minRange,
      'max_range': maxRange,
      'allow_duplicates': allowDuplicates ? 1 : 0,
    };
  }

  factory Draw.fromMap(Map<String, dynamic> map) {
    return Draw(
      id: map['id'] as int?,
      winningNumbers: (map['winning_numbers'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      mode: map['mode'] as String,
      winnersCount: map['winners_count'] as int,
      date: DateTime.parse(map['date'] as String),
      minRange: map['min_range'] as int,
      maxRange: map['max_range'] as int,
      allowDuplicates: map['allow_duplicates'] == 1,
    );
  }
}
