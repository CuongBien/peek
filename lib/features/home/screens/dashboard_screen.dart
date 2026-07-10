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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar details
                  _buildHeader(),
                  Expanded(
                    child: Center(
                      child: _buildRadarContent(),
                    ),
                  ),
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
                color: AppColors.accentBlue.withOpacity(0.8),
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.glassFill,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.security,
                    color: AppColors.accentBlue,
                    size: 22,
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildRadarContent() {
    return BlocBuilder<RadarBloc, RadarState>(
      builder: (context, state) {
        final isScanning = state is RadarScanning;
        final progress = isScanning ? state.progress : 0.0;
        final statusText = isScanning ? state.statusText : "Tap to scan environment";

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                      width: 240, // Tăng kích thước radar một chút cho đẹp khi đứng một mình
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isScanning 
                              ? AppColors.accentCyan.withOpacity(0.15) 
                              : Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 8,
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
            const SizedBox(height: 40),
            // Scanning status details
            Text(
              statusText.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isScanning ? AppColors.accentCyan : AppColors.textPrimary,
                fontSize: 18, // Tăng nhẹ size chữ tiêu đề trạng thái
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isScanning ? "Please hold still while scanning..." : "Tap the scanner core to search for anomalies",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            
            if (isScanning) ...[
              const SizedBox(height: 30),
              // Linear Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: Colors.black.withOpacity(0.05),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: MediaQuery.of(context).size.width * 0.7 * progress,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [AppColors.accentCyan, Colors.blueAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
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
              ),
            ]
          ],
        );
      },
    );
  }


}
