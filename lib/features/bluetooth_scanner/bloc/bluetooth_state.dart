import 'package:flutter/foundation.dart';
import '../services/bluetooth_scanner_service.dart';

@immutable
class BluetoothState {
  final bool isScanning;
  final List<BleDeviceResult> devices;
  final BleDeviceResult? trackingDevice;
  final int proximityScore;
  final String? error;

  const BluetoothState({
    required this.isScanning,
    required this.devices,
    this.trackingDevice,
    required this.proximityScore,
    this.error,
  });

  factory BluetoothState.initial() {
    return const BluetoothState(
      isScanning: false,
      devices: [],
      trackingDevice: null,
      proximityScore: 0,
      error: null,
    );
  }

  BluetoothState copyWith({
    bool? isScanning,
    List<BleDeviceResult>? devices,
    BleDeviceResult? trackingDevice,
    int? proximityScore,
    String? error,
  }) {
    return BluetoothState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      trackingDevice: trackingDevice ?? this.trackingDevice,
      proximityScore: proximityScore ?? this.proximityScore,
      error: error ?? this.error,
    );
  }
}
