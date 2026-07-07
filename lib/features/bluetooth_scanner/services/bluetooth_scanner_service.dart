import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceResult {
  final String deviceId;
  final String name;
  final int rssi;
  final bool isSuspicious;

  BleDeviceResult({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.isSuspicious,
  });
}

class BluetoothScannerService {
  // Ngưỡng RSSI để coi là cực kỳ gần (dưới 1-2 mét). 
  // -50dBm là một mức khá mạnh, chỉ khi để điện thoại sát bên mới đạt được.
  final int dangerRssiThreshold = -50; 
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final StreamController<List<BleDeviceResult>> _resultController = StreamController<List<BleDeviceResult>>.broadcast();

  Stream<List<BleDeviceResult>> get scanResults => _resultController.stream;

  Future<void> startScan() async {
    // Đảm bảo Bluetooth đang bật
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
      throw Exception("Vui lòng bật Bluetooth trên điện thoại.");
    }

    _scanSubscription?.cancel();
    
    // Bắt đầu quét liên tục
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      List<BleDeviceResult> devices = [];
      
      for (ScanResult r in results) {
        String deviceName = r.device.platformName.trim();
        if (deviceName.isEmpty) {
          deviceName = r.advertisementData.advName.trim();
        }

        // --- TIÊU CHÍ NHẬN DIỆN KHẢ NGHI ---
        // 1. Không có tên (Unnamed)
        // 2. RSSI mạnh (Rất gần)
        bool isUnnamed = deviceName.isEmpty;
        bool isVeryClose = r.rssi >= dangerRssiThreshold; // Ví dụ: -45 >= -50
        
        bool suspicious = isUnnamed && isVeryClose;

        devices.add(
          BleDeviceResult(
            deviceId: r.device.remoteId.str,
            name: isUnnamed ? "Thiết bị Ẩn danh (Unnamed)" : deviceName,
            rssi: r.rssi,
            isSuspicious: suspicious,
          )
        );
      }

      // Sắp xếp: Khả nghi lên đầu, sau đó sắp xếp theo cường độ tín hiệu (RSSI) mạnh nhất lên trước
      devices.sort((a, b) {
        if (a.isSuspicious && !b.isSuspicious) return -1;
        if (!a.isSuspicious && b.isSuspicious) return 1;
        return b.rssi.compareTo(a.rssi); 
      });

      _resultController.add(devices);
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  void dispose() {
    stopScan();
    _resultController.close();
  }
}
