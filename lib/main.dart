import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'magnetic_detection_service.dart';

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
      home: const MagneticDetectorScreen(),
    );
  }
}

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

  Future<void> _showNetworkInfo() async {
    // Yêu cầu quyền vị trí (Bắt buộc trên Android 8.1+ để lấy tên Wi-Fi và BSSID)
    var status = await Permission.location.request();
    
    final info = NetworkInfo();
    final wifiName = await info.getWifiName(); 
    final wifiBSSID = await info.getWifiBSSID();
    final wifiIP = await info.getWifiIP();
    final wifiIPv6 = await info.getWifiIPv6();
    final wifiSubmask = await info.getWifiSubmask();
    final wifiBroadcast = await info.getWifiBroadcast();
    final wifiGateway = await info.getWifiGatewayIP();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin Mạng Wi-Fi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.isDenied)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('⚠️ Bạn chưa cấp quyền Vị trí. Tên Wi-Fi có thể không hiển thị được.', style: TextStyle(color: Colors.red)),
                ),
              Text('Tên (SSID): ${wifiName ?? "Không rõ"}'),
              Text('BSSID (MAC): ${wifiBSSID ?? "Không rõ"}'),
              Text('IP: ${wifiIP ?? "Không rõ"}'),
              Text('Gateway: ${wifiGateway ?? "Không rõ"}'),
              Text('Subnet Mask: ${wifiSubmask ?? "Không rõ"}'),
              Text('Broadcast: ${wifiBroadcast ?? "Không rõ"}'),
              Text('IPv6: ${wifiIPv6 ?? "Không rõ"}'),
              const Divider(),
              const Text(
                'Mẹo: Nếu Gateway IP và IP của điện thoại cùng dải, '
                'bạn có thể quét dải mạng này để tìm IP của Camera ẩn.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dò Camera Ẩn / Kim Loại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find),
            tooltip: 'Thông tin Wi-Fi',
            onPressed: _showNetworkInfo,
          ),
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
