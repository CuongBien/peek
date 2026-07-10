import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/radar_bloc.dart';
import '../bloc/radar_event.dart';
import '../bloc/radar_state.dart';
import '../widgets/radar_painter.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../lan_scanner/screens/lan_scanner_screen.dart';
import '../../bluetooth_scanner/screens/bluetooth_scanner_screen.dart';
import '../../magnetic_detector/screens/magnetic_detector_screen.dart';
import 'camera_scan_screen.dart';
import 'results_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RadarBloc, RadarState>(
      listener: (context, state) {
        if (state is RadarScanning) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else {
          _rotationController.stop();
        }

        if (state is RadarSuccess) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResultsScreen(report: state.report),
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: AppTheme.backgroundDecoration,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar details
                  _buildHeader(),
                  const SizedBox(height: 20),
                  
                  // Radar Widget Card
                  _buildRadarCard(),
                  const SizedBox(height: 30),
                  
                  // Section Title
                  const Text(
                    "QUICK ACTIONS",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Action Grid
                  _buildActionsGrid(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SPY SHIELD",
              style: TextStyle(
                color: AppColors.accentCyan.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
            const Text(
              "Peek Camera Detector",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const CircleAvatar(
            backgroundColor: AppColors.glassFill,
            child: Icon(Icons.security, color: AppColors.accentCyan),
          ),
        )
      ],
    );
  }

  Widget _buildRadarCard() {
    return BlocBuilder<RadarBloc, RadarState>(
      builder: (context, state) {
        final isScanning = state is RadarScanning;
        final progress = isScanning ? state.progress : 0.0;
        final statusText = isScanning ? state.statusText : "Tap to scan environment";

        return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Radar view
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (isScanning) {
                      context.read<RadarBloc>().add(StopRadarScan());
                    } else {
                      context.read<RadarBloc>().add(StartRadarScan());
                    }
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_rotationController, _pulseController]),
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isScanning 
                                ? AppColors.accentCyan.withOpacity(0.08) 
                                : Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: CustomPaint(
                          painter: RadarPainter(
                            angle: _rotationController.value * 2 * 3.14159,
                            pulseValue: _pulseController.value,
                            isScanning: isScanning,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 35),
              // Scanning status details
              Text(
                statusText.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isScanning ? AppColors.accentCyan : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isScanning ? "Please hold still while scanning..." : "Tap the scanner core to search for anomalies",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              
              if (isScanning) ...[
                const SizedBox(height: 25),
                // Linear Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: MediaQuery.of(context).size.width * 0.8 * progress,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [AppColors.accentCyan, Colors.blueAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionsGrid() {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'WiFi Scanner',
        'desc': 'Locate camera feeds over LAN',
        'icon': Icons.wifi_find,
        'color': AppColors.accentCyan,
        'screen': const LanScannerScreen(),
      },
      {
        'title': 'Infrared Camera',
        'desc': 'AR lens lens detection',
        'icon': Icons.videocam,
        'color': AppColors.accentRed,
        'screen': const CameraScanScreen(),
      },
      {
        'title': 'Magnetic Sensor',
        'desc': 'Trace metallic parts & lens',
        'icon': Icons.explore,
        'color': Colors.amber,
        'screen': const MagneticDetectorScreen(),
      },
      {
        'title': 'Bluetooth Scanner',
        'desc': 'BLE proximity tracking',
        'icon': Icons.bluetooth_searching,
        'color': AppColors.accentCyan,
        'screen': const BluetoothScannerScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => item['screen']),
            );
          },
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (item['color'] as Color).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    item['icon'],
                    color: item['color'],
                    size: 22,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
