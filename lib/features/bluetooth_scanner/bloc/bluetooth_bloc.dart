import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bluetooth_event.dart';
import 'bluetooth_state.dart';
import '../services/bluetooth_scanner_service.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final BluetoothScannerService _bleService = BluetoothScannerService();
  StreamSubscription<List<BleDeviceResult>>? _scanSub;
  Timer? _scanTimeoutTimer;

  BluetoothBloc() : super(BluetoothState.initial()) {
    on<StartBluetoothScan>(_onStartScan);
    on<StopBluetoothScan>(_onStopScan);
    on<BluetoothResultsUpdated>(_onResultsUpdated);
    on<StartTrackingDevice>(_onStartTracking);
    on<StopTrackingDevice>(_onStopTracking);
    on<UpdateTrackingRssi>(_onUpdateTrackingRssi);
  }

  void _onStartScan(StartBluetoothScan event, Emitter<BluetoothState> emit) async {
    _scanSub?.cancel();
    _scanTimeoutTimer?.cancel();

    emit(state.copyWith(isScanning: true, error: null));

    try {
      await _bleService.startScan();
      _scanSub = _bleService.scanResults.listen((results) {
        add(BluetoothResultsUpdated(results));
      });

      // Scan timeout after 20s
      _scanTimeoutTimer = Timer(const Duration(seconds: 20), () {
        add(StopBluetoothScan());
      });
    } catch (e) {
      emit(state.copyWith(isScanning: false, error: e.toString()));
    }
  }

  void _onStopScan(StopBluetoothScan event, Emitter<BluetoothState> emit) {
    _scanSub?.cancel();
    _scanSub = null;
    _scanTimeoutTimer?.cancel();
    _bleService.stopScan();
    emit(state.copyWith(isScanning: false));
  }

  void _onResultsUpdated(BluetoothResultsUpdated event, Emitter<BluetoothState> emit) {
    List<BleDeviceResult> devices = event.devices;

    // Handle tracking update if currently tracking a device
    BleDeviceResult? currentTracking = state.trackingDevice;
    int proximity = state.proximityScore;

    if (currentTracking != null) {
      try {
        final updatedDevice = devices.firstWhere((d) => d.deviceId == currentTracking!.deviceId);
        currentTracking = updatedDevice;
        proximity = _calculateProximity(updatedDevice.rssi);
      } catch (_) {
        // Tracked device not in this batch, keep previous state
      }
    }

    emit(state.copyWith(
      devices: devices,
      trackingDevice: currentTracking,
      proximityScore: proximity,
    ));
  }

  void _onStartTracking(StartTrackingDevice event, Emitter<BluetoothState> emit) {
    // Keep scanning active if it is, but start tracking a specific device
    final proximity = _calculateProximity(event.device.rssi);
    emit(state.copyWith(
      trackingDevice: event.device,
      proximityScore: proximity,
    ));
  }

  void _onStopTracking(StopTrackingDevice event, Emitter<BluetoothState> emit) {
    emit(state.copyWith(
      trackingDevice: null,
      proximityScore: 0,
    ));
  }

  void _onUpdateTrackingRssi(UpdateTrackingRssi event, Emitter<BluetoothState> emit) {
    if (state.trackingDevice != null) {
      final updatedDevice = BleDeviceResult(
        deviceId: state.trackingDevice!.deviceId,
        name: state.trackingDevice!.name,
        rssi: event.newRssi,
        isSuspicious: state.trackingDevice!.isSuspicious,
      );
      emit(state.copyWith(
        trackingDevice: updatedDevice,
        proximityScore: _calculateProximity(event.newRssi),
      ));
    }
  }

  int _calculateProximity(int rssi) {
    if (rssi <= -100) return 0;
    if (rssi >= -40) return 100;
    return (((rssi + 100) / 60) * 100).round();
  }

  @override
  Future<void> close() {
    _scanSub?.cancel();
    _scanTimeoutTimer?.cancel();
    _bleService.dispose();
    return super.close();
  }
}
