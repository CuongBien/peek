import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../common/models/discovered_device.dart';
import '../services/network_scanner_service.dart';

class LanScannerScreen extends StatefulWidget {
  const LanScannerScreen({Key? key}) : super(key: key);

  @override
  State<LanScannerScreen> createState() => _LanScannerScreenState();
}

class _LanScannerScreenState extends State<LanScannerScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
  final NetworkScannerService _scannerService = NetworkScannerService();
  
  String? _wifiName;
  String? _myIp;
  String? _subnetMask;
  bool _isScanning = false;
  List<DiscoveredDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _fetchNetworkData();
  }

  Future<void> _fetchNetworkData() async {
    await Permission.location.request(); // Bắt buộc cho SSID
    
    final name = await _networkInfo.getWifiName();
    final ip = await _networkInfo.getWifiIP();
    final sm = await _networkInfo.getWifiSubmask();
    
    if (mounted) {
      setState(() {
        _wifiName = name;
        _myIp = ip;
        _subnetMask = sm;
      });
    }
  }

  void _startScan() {
    if (_myIp == null || _subnetMask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy IP hoặc Subnet Mask. Vui lòng kết nối Wi-Fi.')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    _scannerService.scanNetworkForCameras(_myIp!, _subnetMask!).listen(
      (DiscoveredDevice device) {
        setState(() {
          _devices.add(device);
        });
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã quét xong! Tìm thấy ${_devices.length} thiết bị đáng ngờ.')),
        );
      },
      onError: (e) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Camera Wi-Fi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _fetchNetworkData,
          )
        ],
      ),
      body: Column(
        children: [
          // Banner thông tin mạng
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mạng Wi-Fi: ${_wifiName ?? "Không rõ"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('IP Điện thoại: ${_myIp ?? "Đang tải..."}'),
                Text('Subnet Mask: ${_subnetMask ?? "Đang tải..."}'),
              ],
            ),
          ),
          
          // Nút bấm quét
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.radar),
                label: Text(_isScanning ? 'ĐANG QUÉT MẠNG LAN...' : 'BẮT ĐẦU QUÉT CAMERA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

          // Danh sách kết quả
          Expanded(
            child: _devices.isEmpty 
              ? Center(
                  child: Text(
                    _isScanning ? "Đang dò tìm..." : "Bấm nút 'Bắt đầu quét' để tìm Camera",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    
                    // Phân loại mức độ nguy hiểm dựa trên Port
                    bool isHighlySuspicious = device.openPorts.contains(554) || device.openPorts.contains(8000);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isHighlySuspicious ? Colors.red : Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isHighlySuspicious ? Icons.videocam : Icons.router, 
                          color: isHighlySuspicious ? Colors.red : Colors.orange,
                          size: 40,
                        ),
                        title: Text('IP: ${device.ip}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Port đang mở: ${device.openPorts.join(", ")}'),
                            if (device.serverInfo != null && device.serverInfo!.isNotEmpty)
                              Text('Hãng/Server: ${device.serverInfo}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        trailing: isHighlySuspicious 
                            ? const Text('Rất Đáng Ngờ\n(RTSP/Camera)', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
                            : const Text('Có Thể Là\nWeb/Router', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontSize: 12)),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
