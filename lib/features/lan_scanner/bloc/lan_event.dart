import 'package:flutter/foundation.dart';
import '../../../common/models/discovered_device.dart';

@immutable
abstract class LanEvent {}

class FetchLanNetworkInfo extends LanEvent {}

class StartLanScan extends LanEvent {}

class StopLanScan extends LanEvent {}

class LanDeviceDiscovered extends LanEvent {
  final DiscoveredDevice device;
  LanDeviceDiscovered(this.device);
}

class CompleteLanScan extends LanEvent {}

class LanScanError extends LanEvent {
  final String error;
  LanScanError(this.error);
}
