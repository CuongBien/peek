import 'discovered_device.dart';
import '../../features/bluetooth_scanner/services/bluetooth_scanner_service.dart';

enum ThreatLevel { safe, warning, danger }

class ScanReport {
  final DateTime scanTime;
  final List<DiscoveredDevice> wifiDevices;
  final List<BleDeviceResult> bleDevices;
  final double peakMagneticValue;
  final double averageMagneticValue;
  final ThreatLevel overallThreat;
  final List<String> threatsList;

  ScanReport({
    required this.scanTime,
    required this.wifiDevices,
    required this.bleDevices,
    required this.peakMagneticValue,
    required this.averageMagneticValue,
    required this.overallThreat,
    required this.threatsList,
  });

  int get totalDetections => wifiDevices.length + bleDevices.length;
  
  int get suspiciousWifiCount => wifiDevices.where((d) => d.openPorts.contains(554) || d.openPorts.contains(8000)).length;
  int get suspiciousBleCount => bleDevices.where((d) => d.isSuspicious).length;
}
