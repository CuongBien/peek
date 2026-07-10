import 'package:flutter/foundation.dart';
import '../../../common/models/discovered_device.dart';

@immutable
class LanState {
  final bool isScanning;
  final List<DiscoveredDevice> devices;
  final String? wifiName;
  final String? myIp;
  final String? subnetMask;
  final String? error;

  const LanState({
    required this.isScanning,
    required this.devices,
    this.wifiName,
    this.myIp,
    this.subnetMask,
    this.error,
  });

  factory LanState.initial() {
    return const LanState(
      isScanning: false,
      devices: [],
      wifiName: null,
      myIp: null,
      subnetMask: null,
      error: null,
    );
  }

  LanState copyWith({
    bool? isScanning,
    List<DiscoveredDevice>? devices,
    String? wifiName,
    String? myIp,
    String? subnetMask,
    String? error,
  }) {
    return LanState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      wifiName: wifiName ?? this.wifiName,
      myIp: myIp ?? this.myIp,
      subnetMask: subnetMask ?? this.subnetMask,
      error: error ?? this.error,
    );
  }
}
