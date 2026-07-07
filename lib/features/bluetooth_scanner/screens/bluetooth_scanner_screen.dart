import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_scanner_service.dart';

class BluetoothScannerScreen extends StatefulWidget {
  const BluetoothScannerScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScannerScreen> createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends State<BluetoothScannerScreen> {
  final BluetoothScannerService _bleService = BluetoothScannerService();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    // Xin quyền Bluetooth và Vị trí (bắt buộc để quét BLE trên Android)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isGranted == true || 
        statuses[Permission.location]?.isGranted == true) {
      _startScan();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng cấp quyền Bluetooth và Vị trí để quét camera ẩn!')),
        );
      }
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      await _bleService.startScan();
      // Quét tự động dừng sau 15s (do set timeout trong service)
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dò Bluetooth Camera Ẩn'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _isScanning ? null : _startScan,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: const Text(
              'Ứng dụng đang tìm kiếm các thiết bị Bluetooth (BLE) không có tên. '
              'Hãy cầm điện thoại di chuyển quanh phòng. '
              'Nếu thấy thiết bị bị đánh dấu ĐỎ (RSSI cao), hãy kiểm tra khu vực đó ngay lập tức!',
              style: TextStyle(fontSize: 14, color: Colors.indigo),
              textAlign: TextAlign.center,
            ),
          ),
          
          if (_isScanning)
            const LinearProgressIndicator(),

          Expanded(
            child: StreamBuilder<List<BleDeviceResult>>(
              stream: _bleService.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(_isScanning ? 'Đang dò sóng BLE...' : 'Bấm nút kính lúp để quét'),
                  );
                }

                final devices = snapshot.data!;
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: device.isSuspicious ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: device.isSuspicious ? Colors.red : Colors.grey.shade300, 
                          width: device.isSuspicious ? 2 : 1
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          device.isSuspicious ? Icons.warning_rounded : Icons.bluetooth,
                          color: device.isSuspicious ? Colors.red : Colors.grey,
                          size: 32,
                        ),
                        title: Text(
                          device.name, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: device.isSuspicious ? Colors.red : Colors.black87
                          )
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MAC/ID: ${device.deviceId}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            // Hiển thị RSSI dạng thanh màu
                            Row(
                              children: [
                                Text('Cường độ (RSSI): ${device.rssi} dBm', style: const TextStyle(fontWeight: FontWeight.w500)),
                                const Spacer(),
                                _buildRssiIndicator(device.rssi),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isScanning
          ? FloatingActionButton(
              onPressed: () {
                _bleService.stopScan();
                setState(() {
                  _isScanning = false;
                });
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            )
          : null,
    );
  }

  // Tiện ích vẽ cột sóng RSSI
  Widget _buildRssiIndicator(int rssi) {
    Color color;
    int bars;
    if (rssi >= -50) {
      color = Colors.red; // Rất gần
      bars = 4;
    } else if (rssi >= -70) {
      color = Colors.orange; // Gần
      bars = 3;
    } else if (rssi >= -90) {
      color = Colors.blue; // Xa
      bars = 2;
    } else {
      color = Colors.grey; // Rất xa
      bars = 1;
    }

    return Row(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 6,
          height: 8.0 + (index * 4),
          decoration: BoxDecoration(
            color: index < bars ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
