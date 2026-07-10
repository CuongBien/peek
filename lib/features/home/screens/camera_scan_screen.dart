import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../widgets/camera_scan_widgets.dart';
import '../../magnetic_detector/bloc/magnetic_bloc.dart';
import '../../magnetic_detector/bloc/magnetic_event.dart';
import '../../magnetic_detector/bloc/magnetic_state.dart';
import '../../../common/models/magnetic_result.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({Key? key}) : super(key: key);

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  late AnimationController _bracketPulseController;
  late AnimationController _laserScanController;
  late MagneticBloc _magneticBloc;

  @override
  void initState() {
    super.initState();
    _bracketPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _laserScanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _magneticBloc = MagneticBloc()..add(StartMagneticTracking());
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _isCameraError = true);
        return;
      }
      
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCameraError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bracketPulseController.dispose();
    _laserScanController.dispose();
    _cameraController?.dispose();
    _magneticBloc.add(StopMagneticTracking());
    _magneticBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _magneticBloc,
      child: BlocBuilder<MagneticBloc, MagneticState>(
        builder: (context, magState) {
          final result = magState.currentResult;
          final isSuspicious = result != null && result.status == MagneticStatus.danger;
          final statusColor = isSuspicious ? AppColors.accentRed : AppColors.accentCyan;

          return Scaffold(
            body: Stack(
              children: [
                // 1. Camera Viewfinder (Real or Mock simulation)
                _buildCameraViewfinder(isSuspicious),
                
                // 2. Translucent dark filter overlay
                Container(
                  color: Colors.black.withOpacity(0.2),
                ),

                // 3. AR brackets overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: FocusBracketsPainter(
                      isSuspicious: isSuspicious,
                      pulseValue: _bracketPulseController.value,
                    ),
                  ),
                ),

                // 4. Scanning laser beam animation
                _buildLaserBeam(isSuspicious),

                // 5. High-tech HUD overlays
                _buildHUDHeader(context, statusColor, magState),

                // 6. Magnetic EMF waveform graph card at the bottom
                _buildBottomGraphCard(statusColor, isSuspicious, magState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraViewfinder(bool isSuspicious) {
    if (_isCameraInitialized && _cameraController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      );
    }

    // High-tech fallback simulation screen
    return Container(
      color: Colors.black87,
      child: Stack(
        children: [
          // Cyber Grid background
          Opacity(
            opacity: 0.15,
            child: GridPaper(
              color: isSuspicious ? AppColors.accentRed : AppColors.accentCyan,
              divisions: 2,
              subdivisions: 1,
              interval: 40,
            ),
          ),
          
          // Lens aperture vignette effect
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
          
          // Simulated statistics overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  color: (isSuspicious ? AppColors.accentRed : AppColors.accentCyan).withOpacity(0.4),
                  size: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  "INFRARED FILTER ACTIVE",
                  style: TextStyle(
                    color: (isSuspicious ? AppColors.accentRed : AppColors.accentCyan).withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "ISO: 800 | F/2.8 | 60FPS | AR CORE ON",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaserBeam(bool isSuspicious) {
    return AnimatedBuilder(
      animation: _laserScanController,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * _laserScanController.value * 0.7,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: isSuspicious ? AppColors.accentRed.withOpacity(0.8) : AppColors.accentCyan.withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isSuspicious ? AppColors.accentRed : AppColors.accentCyan,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHUDHeader(BuildContext context, Color statusColor, MagneticState magState) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button with glassmorphism
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: GlassCard(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 12,
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
              ),
              
              // Dynamic status indicator (Scanning / Danger)
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 12,
                borderSide: BorderSide(color: statusColor.withOpacity(0.4), width: 1.2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.8),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      magState.statusMessage.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Calibration trigger button
              GestureDetector(
                onTap: () {
                  context.read<MagneticBloc>().add(RecalibrateMagnetic());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Baseline recalibrated for environmental conditions."),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                },
                child: GlassCard(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 12,
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Lens flare warnings
          if (magState.currentResult != null && magState.currentResult!.status == MagneticStatus.danger)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.report, color: AppColors.accentRed, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Lens Magnetic Anomaly Detected! Check the direction.",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomGraphCard(Color statusColor, bool isSuspicious, MagneticState magState) {
    final result = magState.currentResult;
    final double magnitude = result?.magnitude ?? 0.0;
    final double delta = result?.delta ?? 0.0;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: GlassCard(
        blur: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ELECTROMAGNETIC FIELD FLUX",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${magnitude.toStringAsFixed(1)} µT",
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                
                // Anomaly delta score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "DELTA",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} µT",
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 15),

            // EMF Wave Line graph
            SizedBox(
              height: 70,
              width: double.infinity,
              child: CustomPaint(
                painter: WaveGraphPainter(
                  history: magState.history.isEmpty ? [40, 42, 45, 41, 40, 44, 45, 46, 42, 40] : magState.history,
                  isSuspicious: isSuspicious,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "HISTORY RATE: 60Hz",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                Text(
                  "BANDWIDTH: 100 µT",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
