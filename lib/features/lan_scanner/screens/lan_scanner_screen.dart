import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lan_bloc.dart';
import '../bloc/lan_event.dart';
import '../bloc/lan_state.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class LanScannerScreen extends StatefulWidget {
  const LanScannerScreen({Key? key}) : super(key: key);

  @override
  State<LanScannerScreen> createState() => _LanScannerScreenState();
}

class _LanScannerScreenState extends State<LanScannerScreen> {
  late LanBloc _lanBloc;

  @override
  void initState() {
    super.initState();
    _lanBloc = LanBloc()..add(FetchLanNetworkInfo());
  }

  @override
  void dispose() {
    _lanBloc.add(StopLanScan());
    _lanBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _lanBloc,
      child: BlocBuilder<LanBloc, LanState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("LAN WIFI SCANNER"),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: state.isScanning ? AppColors.textMuted : AppColors.accentCyan,
                  ),
                  onPressed: state.isScanning 
                      ? null 
                      : () => context.read<LanBloc>().add(FetchLanNetworkInfo()),
                )
              ],
            ),
            body: Container(
              decoration: AppTheme.backgroundDecoration,
              child: SafeArea(
                child: Column(
                  children: [
                    // Network Info Card
                    _buildNetworkInfoCard(state),
                    
                    // Scan button
                    _buildScanButton(context, state),

                    if (state.isScanning)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: LinearProgressIndicator(
                          minHeight: 2.0,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                        ),
                      ),

                    // Results
                    Expanded(
                      child: state.devices.isEmpty
                          ? _buildEmptyState(state)
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: state.devices.length,
                              itemBuilder: (context, index) {
                                final device = state.devices[index];
                                bool isHighlySuspicious = device.openPorts.contains(554) || device.openPorts.contains(8000);
                                return _buildDeviceCard(device, isHighlySuspicious);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkInfoCard(LanState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wifi_rounded, color: AppColors.accentCyan, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.wifiName ?? "Loading WiFi...",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Local IP: ${state.myIp ?? 'N/A'}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  Text(
                    "Subnet Mask: ${state.subnetMask ?? 'N/A'}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context, LanState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: state.myIp == null
              ? null
              : () {
                  if (state.isScanning) {
                    context.read<LanBloc>().add(StopLanScan());
                  } else {
                    context.read<LanBloc>().add(StartLanScan());
                  }
                },
          icon: state.isScanning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Icon(Icons.radar_rounded, color: Colors.black),
          label: Text(
            state.isScanning ? "STOP SCANNING" : "START PORT DISCOVERY",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isScanning ? AppColors.accentRed : AppColors.accentCyan,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.router_rounded,
              color: AppColors.textMuted.withOpacity(0.3),
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              state.isScanning ? "Scanning LAN Subnet..." : "Standby Mode",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              state.isScanning
                  ? "Pinging nodes and mapping active ports..."
                  : "Start scanning to identify cameras streaming on port 554/80/8080",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(var device, bool isHighlySuspicious) {
    final statusColor = isHighlySuspicious ? AppColors.accentRed : AppColors.accentCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderSide: BorderSide(
          color: isHighlySuspicious ? AppColors.accentRed.withOpacity(0.3) : AppColors.glassBorder,
          width: 1.2,
        ),
        fillCol: isHighlySuspicious ? AppColors.accentRed.withOpacity(0.02) : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isHighlySuspicious ? Icons.videocam : Icons.router,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "IP: ${device.ip}",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Open Ports: ${device.openPorts.join(', ')}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  if (device.serverInfo != null && device.serverInfo!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Server: ${device.serverInfo}",
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    isHighlySuspicious ? "RTSP / CAM" : "HOST",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
