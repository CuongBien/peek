class DiscoveredDevice {
  final String ip;
  final List<int> openPorts;
  final String? serverInfo; // Tên thiết bị hoặc hãng sản xuất

  DiscoveredDevice({
    required this.ip, 
    required this.openPorts,
    this.serverInfo,
  });
}
