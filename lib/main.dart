import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'magnetic_detection_service.dart';
import 'network_scanner_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spy Camera Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

// === MAIN SCREEN (Chứa BottomNavigationBar) ===
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const MagneticDetectorScreen(),
    const LanScannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Từ Trường',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_tethering),
            label: 'Quét Wi-Fi',
          ),
        ],
      ),
    );
  }
}

// === MÀN HÌNH 1: DÒ TỪ TRƯỜNG ===
class MagneticDetectorScreen extends StatefulWidget {
  const MagneticDetectorScreen({Key? key}) : super(key: key);

  @override
  State<MagneticDetectorScreen> createState() => _MagneticDetectorScreenState();
}

class _MagneticDetectorScreenState extends State<MagneticDetectorScreen> {
  final _magneticService = MagneticDetectionService();

  @override
  void initState() {
    super.initState();
    _magneticService.startScanning();
  }

  @override
  void dispose() {
    _magneticService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dò Camera Ẩn / Kim Loại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Hiệu chuẩn lại (Recalibrate)',
            onPressed: () {
              _magneticService.recalibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã hiệu chuẩn lại môi trường nền'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<MagneticResult>(
        stream: _magneticService.getOptimizedUIStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data!;
          
          Color bgColor;
          String statusText;
          IconData statusIcon;
          Color textColor = Colors.black87;

          switch (result.status) {
            case MagneticStatus.danger:
              bgColor = Colors.red.shade400;
              statusText = 'NGUY HIỂM\nPhát hiện từ tính mạnh!';
              statusIcon = Icons.warning_rounded;
              textColor = Colors.white;
              break;
            case MagneticStatus.warning:
              bgColor = Colors.orange.shade300;
              statusText = 'CẢNH BÁO\nTừ tính tăng bất thường';
              statusIcon = Icons.warning_amber_rounded;
              break;
            case MagneticStatus.normal:
            default:
              bgColor = Colors.green.shade300;
              statusText = 'AN TOÀN\nKhông phát hiện bất thường';
              statusIcon = Icons.check_circle_outline;
              textColor = Colors.white;
              break;
          }

          return Container(
            color: bgColor,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, size: 100, color: textColor),
                const SizedBox(height: 20),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Độ lớn hiện tại: ${result.magnitude.toStringAsFixed(1)} µT',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đường cơ sở nền: ${result.baseline.toStringAsFixed(1)} µT',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const Divider(height: 20, thickness: 1.5),
                      Text(
                        'Độ lệch: ${result.delta.toStringAsFixed(1)} µT',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: result.status == MagneticStatus.normal ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// === MÀN HÌNH 2: QUÉT MẠNG LAN (TCP SOCKET) ===
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
                        subtitle: Text('Port đang mở: ${device.openPorts.join(", ")}'),
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
