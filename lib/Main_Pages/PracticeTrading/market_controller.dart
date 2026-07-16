// market_time_controller.dart
import 'dart:async';
import 'package:get/get.dart';

class MarketTimeController extends GetxController {
  // Replay window
  static const replayStart = Duration(hours: 16, minutes: 0); // 4:00 PM
  static const replayEnd = Duration(hours: 22, minutes: 15); // 10:15 PM

  // Live market hours
  static const marketStart = Duration(hours: 9, minutes: 15);
  static const marketEnd = Duration(hours: 15, minutes: 30);

  // Shift replay time back to market time (16:00 -> 09:15 = 6h45m)
  static final shift = replayStart - marketStart;

  final now = DateTime.now().obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();

    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Duration get _todDuration => Duration(
        hours: now.value.hour,
        minutes: now.value.minute,
        seconds: now.value.second,
      );

  bool get isReplayWindow =>
      _todDuration >= replayStart && _todDuration <= replayEnd;

  bool get isLiveMarketWindow =>
      _todDuration >= marketStart && _todDuration <= marketEnd;

  /// Maps replay clock (4:00 PM - 10:15 PM) to market time (9:15 AM - 3:30 PM),
  /// preserving seconds.
  DateTime get mappedMarketTime {
    final totalSeconds = _todDuration.inSeconds - shift.inSeconds;
    final wrappedSeconds =
        ((totalSeconds % 86400) + 86400) % 86400; // wrap within 24 hours

    final base = DateTime(now.value.year, now.value.month, now.value.day);

    return base.add(Duration(seconds: wrappedSeconds));
  }

  String get displayLabel {
    if (isReplayWindow) {
      final t = mappedMarketTime;
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      final s = t.second.toString().padLeft(2, '0');
      return 'Market Time: $h:$m:$s';
    } else if (isLiveMarketWindow) {
      return 'Live Market Hours';
    } else {
      return 'Market Closed';
    }
  }
}
