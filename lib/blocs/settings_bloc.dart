import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../database/database_helper.dart';
import '../models/settings_model.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}
class UpdateTheme extends SettingsEvent {
  final String theme;
  const UpdateTheme(this.theme);
  @override
  List<Object?> get props => [theme];
}
class UpdateMinRange extends SettingsEvent {
  final int min;
  const UpdateMinRange(this.min);
  @override
  List<Object?> get props => [min];
}
class UpdateMaxRange extends SettingsEvent {
  final int max;
  const UpdateMaxRange(this.max);
  @override
  List<Object?> get props => [max];
}
class UpdateDefaultWinners extends SettingsEvent {
  final int count;
  const UpdateDefaultWinners(this.count);
  @override
  List<Object?> get props => [count];
}
class ToggleSound extends SettingsEvent {}
class ToggleVibration extends SettingsEvent {}
class ToggleAnimations extends SettingsEvent {}
class ToggleDuplicates extends SettingsEvent {}
class UpdateDrawMode extends SettingsEvent {
  final String mode;
  const UpdateDrawMode(this.mode);
  @override
  List<Object?> get props => [mode];
}

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}
class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  const SettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}
class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final DatabaseHelper _database;
  AppSettings? _currentSettings;

  SettingsBloc({DatabaseHelper? database})
      : _database = database ?? DatabaseHelper.instance,
        super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateMinRange>(_onUpdateMinRange);
    on<UpdateMaxRange>(_onUpdateMaxRange);
    on<UpdateDefaultWinners>(_onUpdateDefaultWinners);
    on<ToggleSound>(_onToggleSound);
    on<ToggleVibration>(_onToggleVibration);
    on<ToggleAnimations>(_onToggleAnimations);
    on<ToggleDuplicates>(_onToggleDuplicates);
    on<UpdateDrawMode>(_onUpdateDrawMode);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      _currentSettings = await _database.getSettings();
      emit(SettingsLoaded(_currentSettings!));
    } catch (e) {
      emit(SettingsError('Erreur lors du chargement des paramètres: $e'));
    }
  }

  Future<void> _onUpdateTheme(UpdateTheme event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(theme: event.theme);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onUpdateMinRange(UpdateMinRange event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(minDefault: event.min);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onUpdateMaxRange(UpdateMaxRange event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(maxDefault: event.max);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onUpdateDefaultWinners(UpdateDefaultWinners event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(defaultWinnersCount: event.count);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onToggleSound(ToggleSound event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(soundEnabled: !_currentSettings!.soundEnabled);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onToggleVibration(ToggleVibration event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(vibrationEnabled: !_currentSettings!.vibrationEnabled);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onToggleAnimations(ToggleAnimations event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(animationsEnabled: !_currentSettings!.animationsEnabled);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onToggleDuplicates(ToggleDuplicates event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(allowDuplicates: !_currentSettings!.allowDuplicates);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _onUpdateDrawMode(UpdateDrawMode event, Emitter<SettingsState> emit) async {
    if (_currentSettings == null) return;
    final newSettings = _currentSettings!.copyWith(drawMode: event.mode);
    await _saveSettings(newSettings, emit);
  }

  Future<void> _saveSettings(AppSettings settings, Emitter<SettingsState> emit) async {
    try {
      await _database.updateSettings(settings);
      _currentSettings = settings;
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Erreur lors de la sauvegarde: $e'));
    }
  }
}
