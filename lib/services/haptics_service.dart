import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

abstract class HapticsService {
  static HapticsService instance = const SystemHapticsService();

  Future<void> lightImpact();
  Future<void> heavyImpact();
  Future<bool> canVibrate();
}

class SystemHapticsService implements HapticsService {
  const SystemHapticsService();

  Future<void> _vibrate({required int duration, int? amplitude}) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) {
      throw StateError('No vibrator');
    }
    final supportsAmplitude = await Vibration.hasAmplitudeControl();
    if (supportsAmplitude == true && amplitude != null) {
      await Vibration.vibrate(duration: duration, amplitude: amplitude);
    } else {
      await Vibration.vibrate(duration: duration);
    }
  }

  @override
  Future<void> lightImpact() async {
    try {
      await _vibrate(duration: 24, amplitude: 80);
    } catch (_) {
      await HapticFeedback.lightImpact();
    }
  }

  @override
  Future<void> heavyImpact() async {
    try {
      await _vibrate(duration: 42, amplitude: 180);
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }
  }

  @override
  Future<bool> canVibrate() async {
    try {
      return (await Vibration.hasVibrator()) == true;
    } catch (_) {
      return false;
    }
  }
}
