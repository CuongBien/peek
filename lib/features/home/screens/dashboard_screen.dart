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
      duration: const Duration(milliseconds: 1500),
    );
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
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _rotationController.stop();
          _pulseController.stop();
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
                  
                  const SizedBox(height: 10),
                  _buildInfraredCameraCard(),
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

  Widget _buildInfraredCameraCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.videocam_rounded, color: AppColors.accentRed, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AR Lens Finder",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Scan camera lens reflections with AR markers",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CameraScanScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: const Text(
              "Launch",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
