import 'package:vibration/vibration.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _enabled = true;

  void setEnabled(bool enabled) => _enabled = enabled;

  Future<void> lightVibration() async {
    if (!_enabled) return;
    await Vibration.vibrate(duration: 50);
  }

  Future<void> mediumVibration() async {
    if (!_enabled) return;
    await Vibration.vibrate(duration: 100);
  }

  Future<void> successVibration() async {
    if (!_enabled) return;
    await Vibration.vibrate(pattern: [0, 100, 50, 100]);
  }

  Future<void> selectionClick() async {
    if (!_enabled) return;
    await Vibration.vibrate(duration: 30);
  }
}
