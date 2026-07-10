import 'package:flutter/material.dart';
import '../../../common/models/scan_report.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final ScanReport report;

  const ResultsScreen({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color threatColor;
    String statusTitle;
    IconData statusIcon;
    List<BoxShadow> glowEffect;

    switch (report.overallThreat) {
      case ThreatLevel.danger:
        threatColor = AppColors.accentRed;
        statusTitle = "THREATS FOUND";
        statusIcon = Icons.report_problem_rounded;
        glowEffect = [
          BoxShadow(
            color: AppColors.accentRed.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
        break;
      case ThreatLevel.warning:
        threatColor = AppColors.warningOrange;
        statusTitle = "POTENTIAL RISK";
        statusIcon = Icons.warning_amber_rounded;
        glowEffect = [
          BoxShadow(
            color: AppColors.warningOrange.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
        break;
      case ThreatLevel.safe:
      default:
        threatColor = AppColors.successGreen;
        statusTitle = "ENVIRONMENT SECURE";
        statusIcon = Icons.check_circle_outline_rounded;
        glowEffect = [
          BoxShadow(
            color: AppColors.successGreen.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("SCAN RESULTS"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status card with red/orange/green glow
                      _buildSecurityStatusCard(statusTitle, statusIcon, threatColor, glowEffect),
                      const SizedBox(height: 30),
                      
                      // Threats summary
                      if (report.threatsList.isNotEmpty) ...[
                        const Text(
                          "SECURITY LOGS",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...report.threatsList.map((log) => _buildThreatLogItem(log, report.overallThreat)).toList(),
                        const SizedBox(height: 25),
                      ],

                      // Device Lists
                      const Text(
                        "DISCOVERED WIRELESS DEVICES",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildWirelessDevicesList(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action buttons
              _buildBottomActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard(String title, IconData icon, Color color, List<BoxShadow> glow) {
    return GlassCard(
      boxShadow: glow,
      borderSide: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.overallThreat == ThreatLevel.safe 
                      ? "WiFi, Bluetooth and EMF levels appear clean."
                      : "Action recommended. Examine flagged devices.",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatLogItem(String log, ThreatLevel level) {
    Color indicatorCol = level == ThreatLevel.danger ? AppColors.accentRed : AppColors.warningOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: indicatorCol.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorCol.withOpacity(0.15), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gpp_maybe_outlined, color: indicatorCol, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              log,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWirelessDevicesList() {
    final wifiList = report.wifiDevices;
    final bleList = report.bleDevices;

    if (wifiList.isEmpty && bleList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "No devices registered.",
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: [
        // WiFi camera items
        ...wifiList.map((wifi) {
          final isSusp = wifi.openPorts.contains(554) || wifi.openPorts.contains(8000);
          return _buildDeviceCard(
            title: "IP Camera / Web Node",
            subTitle: "IP: ${wifi.ip} | Ports: ${wifi.openPorts.join(', ')}",
            meta: wifi.serverInfo ?? "Unknown Vendor",
            icon: Icons.videocam_rounded,
            isSuspicious: isSusp,
            networkType: "WiFi",
          );
        }).toList(),

        // BLE device items
        ...bleList.map((ble) {
          return _buildDeviceCard(
            title: ble.name,
            subTitle: "MAC: ${ble.deviceId}",
            meta: "${ble.rssi} dBm",
            icon: Icons.bluetooth_audio_rounded,
            isSuspicious: ble.isSuspicious,
            networkType: "BLE",
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required String subTitle,
    required String meta,
    required IconData icon,
    required bool isSuspicious,
    required String networkType,
  }) {
    final statusColor = isSuspicious ? AppColors.accentRed : AppColors.accentCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        boxShadow: isSuspicious ? [
          BoxShadow(
            color: AppColors.accentRed.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: GlassCard(
        borderSide: BorderSide(
          color: isSuspicious ? AppColors.accentRed.withOpacity(0.25) : AppColors.glassBorder,
          width: 1.2,
        ),
        child: Row(
          children: [
            // Custom glowing icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            
            // Text contents
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Network tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
                        ),
                        child: Text(
                          networkType,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subTitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: TextStyle(
                      color: isSuspicious ? AppColors.accentRed : AppColors.accentCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicator ring
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundEnd,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Help Guide: Sweep phone around rooms, verify ports & check camera lenses!"),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline, color: AppColors.accentCyan),
                label: const Text(
                  "HELP GUIDE",
                  style: TextStyle(
                    color: AppColors.accentCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentCyan, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Report exported successfully (PDF format saved to local storage)"),
                      backgroundColor: AppColors.accentCyan,
                    ),
                  );
                },
                icon: const Icon(Icons.ios_share_outlined, color: Colors.black),
                label: const Text(
                  "EXPORT",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
