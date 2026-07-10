import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'magnetic_event.dart';
import 'magnetic_state.dart';
import '../services/magnetic_detection_service.dart';
import '../../../common/models/magnetic_result.dart';

class MagneticBloc extends Bloc<MagneticEvent, MagneticState> {
  final MagneticDetectionService _service = MagneticDetectionService();
  StreamSubscription<MagneticResult>? _subscription;
  static const int maxHistorySize = 50;

  MagneticBloc() : super(MagneticState.initial()) {
    on<StartMagneticTracking>(_onStartTracking);
    on<StopMagneticTracking>(_onStopTracking);
    on<MagneticDataUpdated>(_onDataUpdated);
    on<RecalibrateMagnetic>(_onRecalibrate);
  }

  void _onStartTracking(StartMagneticTracking event, Emitter<MagneticState> emit) {
    _subscription?.cancel();
    _service.startScanning();
    
    emit(state.copyWith(
      isTracking: true,
      statusMessage: "Calibrating magnetic flux...",
    ));

    _subscription = _service.getOptimizedUIStream().listen((result) {
      add(MagneticDataUpdated(result));
    });
  }

  void _onStopTracking(StopMagneticTracking event, Emitter<MagneticState> emit) {
    _subscription?.cancel();
    _subscription = null;
    _service.dispose();
    emit(state.copyWith(
      isTracking: false,
      statusMessage: "Sensor offline",
    ));
  }

  void _onDataUpdated(MagneticDataUpdated event, Emitter<MagneticState> emit) {
    final result = event.result;
    final currentHistory = List<double>.from(state.history);
    
    // Add delta or absolute magnitude to the graph
    currentHistory.add(result.magnitude);
    if (currentHistory.length > maxHistorySize) {
      currentHistory.removeAt(0);
    }

    String msg = "SCANNING...";
    if (result.status == MagneticStatus.danger) {
      msg = "SUSPICIOUS ACTIVITY!";
    } else if (result.status == MagneticStatus.warning) {
      msg = "WARNING: HIGH FLUCTUATION";
    }

    emit(state.copyWith(
      currentResult: result,
      history: currentHistory,
      statusMessage: msg,
    ));
  }

  void _onRecalibrate(RecalibrateMagnetic event, Emitter<MagneticState> emit) {
    _service.recalibrate();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _service.dispose();
    return super.close();
  }
}
