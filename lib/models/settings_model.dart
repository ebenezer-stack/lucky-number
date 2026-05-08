class AppSettings {
  final int? id;
  final int minDefault;
  final int maxDefault;
  final int defaultWinnersCount;
  final String theme;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool animationsEnabled;
  final bool allowDuplicates;
  final String drawMode;

  AppSettings({
    this.id,
    this.minDefault = 1,
    this.maxDefault = 100,
    this.defaultWinnersCount = 1,
    this.theme = 'system',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.animationsEnabled = true,
    this.allowDuplicates = false,
    this.drawMode = 'random',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'min_default': minDefault,
      'max_default': maxDefault,
      'default_winners_count': defaultWinnersCount,
      'theme': theme,
      'sound_enabled': soundEnabled ? 1 : 0,
      'vibration_enabled': vibrationEnabled ? 1 : 0,
      'animations_enabled': animationsEnabled ? 1 : 0,
      'allow_duplicates': allowDuplicates ? 1 : 0,
      'draw_mode': drawMode,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int?,
      minDefault: map['min_default'] as int,
      maxDefault: map['max_default'] as int,
      defaultWinnersCount: map['default_winners_count'] as int,
      theme: map['theme'] as String,
      soundEnabled: map['sound_enabled'] == 1,
      vibrationEnabled: map['vibration_enabled'] == 1,
      animationsEnabled: map['animations_enabled'] == 1,
      allowDuplicates: map['allow_duplicates'] == 1,
      drawMode: map['draw_mode'] as String,
    );
  }

  AppSettings copyWith({
    int? id,
    int? minDefault,
    int? maxDefault,
    int? defaultWinnersCount,
    String? theme,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? animationsEnabled,
    bool? allowDuplicates,
    String? drawMode,
  }) {
    return AppSettings(
      id: id ?? this.id,
      minDefault: minDefault ?? this.minDefault,
      maxDefault: maxDefault ?? this.maxDefault,
      defaultWinnersCount: defaultWinnersCount ?? this.defaultWinnersCount,
      theme: theme ?? this.theme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      allowDuplicates: allowDuplicates ?? this.allowDuplicates,
      drawMode: drawMode ?? this.drawMode,
    );
  }
}
