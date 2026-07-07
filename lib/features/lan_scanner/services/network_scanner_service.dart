import 'dart:async';
import 'dart:io';
import '../../../common/models/discovered_device.dart';

class NetworkScannerService {
  // Các cổng phổ biến của Camera IP
  final List<int> _cameraPorts = [554, 80, 8080, 8000];

  /// Chuyển chuỗi IP thành số nguyên
  int _ipToInt(String ipAddress) {
    final parts = ipAddress.split('.');
    if (parts.length != 4) return 0;
    int result = 0;
    for (int i = 0; i < 4; i++) {
      result |= (int.parse(parts[i]) << ((3 - i) * 8));
    }
    return result;
  }

  /// Chuyển số nguyên thành chuỗi IP
  String _intToIp(int ip) {
    return '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.${ip & 0xFF}';
  }

  /// Lấy danh sách IP khả dụng trong mạng
  List<String> getUsableIpRange(String ip, String subnetMask) {
    int ipInt = _ipToInt(ip);
    int maskInt = _ipToInt(subnetMask);

    if (ipInt == 0 || maskInt == 0) return [];

    int networkInt = ipInt & maskInt;
    int invertedMask = (~maskInt) & 0xFFFFFFFF;
    int broadcastInt = networkInt | invertedMask;

    int startIp = networkInt + 1;
    int endIp = broadcastInt - 1;

    List<String> ipList = [];
    for (int i = startIp; i <= endIp; i++) {
      ipList.add(_intToIp(i));
    }
    return ipList;
  }

  /// Quét mạng LAN để tìm Camera (Sử dụng Stream để trả kết quả realtime)
  Stream<DiscoveredDevice> scanNetworkForCameras(String myIp, String subnetMask) async* {
    List<String> ipsToScan = getUsableIpRange(myIp, subnetMask);
    
    // Loại bỏ chính IP của điện thoại để khỏi mất công quét
    ipsToScan.remove(myIp);

    // Giảm batchSize xuống thật thấp để tránh làm treo Event Loop và gây lỗi ANR trên điện thoại
    final int batchSize = 5; 
    
    for (int i = 0; i < ipsToScan.length; i += batchSize) {
      final end = (i + batchSize < ipsToScan.length) ? i + batchSize : ipsToScan.length;
      final currentBatch = ipsToScan.sublist(i, end);

      // Quét song song các IP trong batch hiện tại
      final List<Future<DiscoveredDevice?>> futures = [];
      
      for (String targetIp in currentBatch) {
        futures.add(_scanSingleIp(targetIp));
      }

      // Đợi kết quả của batch này
      final results = await Future.wait(futures);
      
      // Đẩy các thiết bị tìm thấy lên Stream
      for (var device in results) {
        if (device != null) {
          yield device;
        }
      }
      
      // QUAN TRỌNG: Dừng một nhịp nhỏ giữa các đợt quét để nhường CPU cho UI (Tránh ANR)
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Quét các port của một IP cụ thể
  Future<DiscoveredDevice?> _scanSingleIp(String ip) async {
    List<int> openPorts = [];

    // Quét song song các cổng trên cùng 1 IP
    List<Future<void>> portFutures = [];
    
    for (int port in _cameraPorts) {
      portFutures.add(
        Socket.connect(ip, port, timeout: const Duration(milliseconds: 300)).then((socket) {
          // Kết nối thành công
          openPorts.add(port);
          socket.destroy(); // Đóng kết nối ngay lập tức
        }).catchError((error) {
          // Kết nối thất bại (Timeout hoặc Refused)
          // Bỏ qua lỗi
        })
      );
    }

    await Future.wait(portFutures);

    if (openPorts.isNotEmpty) {
      return DiscoveredDevice(ip: ip, openPorts: openPorts);
    }
    return null; // Không tìm thấy cổng mở nào
  }
}
