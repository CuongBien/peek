import 'package:flutter/foundation.dart';
import '../../../common/models/magnetic_result.dart';

@immutable
class MagneticState {
  final bool isTracking;
  final MagneticResult? currentResult;
  final List<double> history;
  final String statusMessage;

  const MagneticState({
    required this.isTracking,
    this.currentResult,
    required this.history,
    required this.statusMessage,
  });

  factory MagneticState.initial() {
    return const MagneticState(
      isTracking: false,
      currentResult: null,
      history: [],
      statusMessage: "Initializing sensor...",
    );
  }

  MagneticState copyWith({
    bool? isTracking,
    MagneticResult? currentResult,
    List<double>? history,
    String? statusMessage,
  }) {
    return MagneticState(
      isTracking: isTracking ?? this.isTracking,
      currentResult: currentResult ?? this.currentResult,
      history: history ?? this.history,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
