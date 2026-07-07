import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../common/models/discovered_device.dart';

class NetworkScannerService {
  // Các cổng phổ biến của Camera IP
  final List<int> _cameraPorts = [554, 80, 8080, 8000];

  int _ipToInt(String ipAddress) {
    final parts = ipAddress.split('.');
    if (parts.length != 4) return 0;
    int result = 0;
    for (int i = 0; i < 4; i++) {
      result |= (int.parse(parts[i]) << ((3 - i) * 8));
    }
    return result;
  }

  String _intToIp(int ip) {
    return '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.${ip & 0xFF}';
  }

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

  Stream<DiscoveredDevice> scanNetworkForCameras(String myIp, String subnetMask) async* {
    List<String> ipsToScan = getUsableIpRange(myIp, subnetMask);
    ipsToScan.remove(myIp);

    final int batchSize = 5; 
    
    for (int i = 0; i < ipsToScan.length; i += batchSize) {
      final end = (i + batchSize < ipsToScan.length) ? i + batchSize : ipsToScan.length;
      final currentBatch = ipsToScan.sublist(i, end);

      final List<Future<DiscoveredDevice?>> futures = [];
      
      for (String targetIp in currentBatch) {
        futures.add(_scanSingleIp(targetIp));
      }

      final results = await Future.wait(futures);
      
      for (var device in results) {
        if (device != null) {
          yield device;
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<DiscoveredDevice?> _scanSingleIp(String ip) async {
    List<int> openPorts = [];
    String? deviceServerInfo;

    List<Future<void>> portFutures = [];
    
    for (int port in _cameraPorts) {
      portFutures.add(
        Socket.connect(ip, port, timeout: const Duration(milliseconds: 300)).then((socket) async {
          openPorts.add(port);
          
          try {
            // Gửi tín hiệu thăm dò (Fingerprinting)
            if (port == 80 || port == 8080) {
              // HTTP Request
              socket.write("GET / HTTP/1.1\r\nHost: $ip\r\nConnection: close\r\n\r\n");
            } else if (port == 554) {
              // RTSP Request
              socket.write("OPTIONS rtsp://$ip:554 RTSP/1.0\r\nCSeq: 1\r\n\r\n");
            }

            if (port == 80 || port == 8080 || port == 554) {
              // Chờ phản hồi trong tối đa 500ms
              await socket.listen((data) {
                String response = utf8.decode(data, allowMalformed: true);
                
                // Trích xuất "Server:" từ Header
                RegExp serverRegex = RegExp(r'Server:\s*(.+)\r\n', caseSensitive: false);
                var match = serverRegex.firstMatch(response);
                if (match != null && deviceServerInfo == null) {
                  deviceServerInfo = match.group(1)?.trim();
                }
              }).asFuture().timeout(const Duration(milliseconds: 500));
            }
          } catch (e) {
            // Bỏ qua lỗi đọc luồng hoặc timeout đọc
          } finally {
            socket.destroy();
          }
        }).catchError((error) {
          // Kết nối thất bại (Timeout hoặc Refused), bỏ qua
        })
      );
    }

    await Future.wait(portFutures);

    if (openPorts.isNotEmpty) {
      return DiscoveredDevice(
        ip: ip, 
        openPorts: openPorts, 
        serverInfo: deviceServerInfo,
      );
    }
    return null; 
  }
}
