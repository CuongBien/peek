import 'package:flutter/foundation.dart';
import '../services/bluetooth_scanner_service.dart';

@immutable
abstract class BluetoothEvent {}

class StartBluetoothScan extends BluetoothEvent {}

class StopBluetoothScan extends BluetoothEvent {}

class BluetoothResultsUpdated extends BluetoothEvent {
  final List<BleDeviceResult> devices;
  BluetoothResultsUpdated(this.devices);
}

class StartTrackingDevice extends BluetoothEvent {
  final BleDeviceResult device;
  StartTrackingDevice(this.device);
}

class StopTrackingDevice extends BluetoothEvent {}

class UpdateTrackingRssi extends BluetoothEvent {
  final int newRssi;
  UpdateTrackingRssi(this.newRssi);
}
