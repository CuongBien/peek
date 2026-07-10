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
  final bool isCameraActive;

  const CameraScanScreen({Key? key, this.isCameraActive = true}) : super(key: key);

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
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
    
    if (widget.isCameraActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(CameraScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCameraActive != oldWidget.isCameraActive) {
      if (widget.isCameraActive) {
        _initializeCamera();
      } else {
        _deinitializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
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
    } catch (_) {}
  }

  Future<void> _deinitializeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
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
          final statusColor = isSuspicious ? AppColors.accentRed : AppColors.accentBlue;
          final double magnitude = result?.magnitude ?? 0.0;
          final double delta = result?.delta ?? 0.0;

          return Scaffold(
            body: Stack(
              children: [
                // 1. Full Screen Camera Viewfinder (Real or Mock simulation)
                Positioned.fill(
                  child: _buildCameraViewfinder(isSuspicious),
                ),
                
                // 2. Translucent dark filter overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                  ),
                ),

                // 3. AR focus brackets overlay
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

                // 5. Floating Dynamic status indicator (top center)
                _buildFloatingStatusHeader(statusColor, magState),

                // 6. Minimal Electromagnetic floating badge (bottom center)
                _buildMinimalEMFBadge(statusColor, magnitude, delta),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraViewfinder(bool isSuspicious) {
    if (widget.isCameraActive && _isCameraInitialized && _cameraController != null) {
      return Center(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1080,
              height: _cameraController!.value.previewSize?.width ?? 1920,
              child: CameraPreview(_cameraController!),
            ),
          ),
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
            opacity: 0.1,
            child: GridPaper(
              color: isSuspicious ? AppColors.accentRed : AppColors.accentBlue,
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
                  color: (isSuspicious ? AppColors.accentRed : AppColors.accentBlue).withOpacity(0.4),
                  size: 50,
                ),
                const SizedBox(height: 12),
                Text(
                  "INFRARED FILTER ACTIVE",
                  style: TextStyle(
                    color: (isSuspicious ? AppColors.accentRed : AppColors.accentBlue).withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "ISO: 640 | F/2.0 | 60FPS | AR MODE",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 9,
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
          top: MediaQuery.of(context).size.height * _laserScanController.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: isSuspicious ? AppColors.accentRed.withOpacity(0.6) : AppColors.accentBlue.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isSuspicious ? AppColors.accentRed : AppColors.accentBlue,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingStatusHeader(Color statusColor, MagneticState magState) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40), // Spacer for balance
              
              // Dynamic status indicator (Scanning / Danger)
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 12,
                borderSide: BorderSide(color: statusColor.withOpacity(0.3), width: 1.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor,
                            blurRadius: 4,
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
                        fontSize: 10,
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
                      backgroundColor: AppColors.accentBlue,
                    ),
                  );
                },
                child: GlassCard(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 10,
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          if (magState.currentResult != null && magState.currentResult!.status == MagneticStatus.danger) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.report, color: AppColors.accentRed, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lens Magnetic Anomaly Detected!",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMinimalEMFBadge(Color statusColor, double magnitude, double delta) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Center(
        child: GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_rounded, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                "EMF: ${magnitude.toStringAsFixed(1)} µT",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 1.0,
                height: 12,
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
              const SizedBox(width: 10),
              Text(
                "Delta: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} µT",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
