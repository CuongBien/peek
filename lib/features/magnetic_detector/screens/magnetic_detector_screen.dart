import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/magnetic_bloc.dart';
import '../bloc/magnetic_event.dart';
import '../bloc/magnetic_state.dart';
import '../../../common/models/magnetic_result.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/widgets/camera_scan_widgets.dart';

class MagneticDetectorScreen extends StatefulWidget {
  const MagneticDetectorScreen({Key? key}) : super(key: key);

  @override
  State<MagneticDetectorScreen> createState() => _MagneticDetectorScreenState();
}

class _MagneticDetectorScreenState extends State<MagneticDetectorScreen> {
  late MagneticBloc _magneticBloc;

  @override
  void initState() {
    super.initState();
    _magneticBloc = MagneticBloc()..add(StartMagneticTracking());
  }

  @override
  void dispose() {
    _magneticBloc.add(StopMagneticTracking());
    _magneticBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _magneticBloc,
      child: BlocBuilder<MagneticBloc, MagneticState>(
        builder: (context, state) {
          final result = state.currentResult;
          final double magnitude = result?.magnitude ?? 0.0;
          final double delta = result?.delta ?? 0.0;
          final double baseline = result?.baseline ?? 0.0;
          
          final isDanger = result != null && result.status == MagneticStatus.danger;
          final isWarning = result != null && result.status == MagneticStatus.warning;
          
          Color statusColor = AppColors.successGreen;
          String statusText = "SAFE ENVIRONMENT";
          IconData statusIcon = Icons.check_circle_outline;
          if (isDanger) {
            statusColor = AppColors.accentRed;
            statusText = "HIGH FLUCTUATION DETECTED!";
            statusIcon = Icons.warning_rounded;
          } else if (isWarning) {
            statusColor = AppColors.warningOrange;
            statusText = "MODERATE MAGNETIC CHANGE";
            statusIcon = Icons.warning_amber_rounded;
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text("MAGNETIC DETECTOR"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<MagneticBloc>().add(RecalibrateMagnetic());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Baseline calibrated to current magnetic surroundings."),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                  },
                )
              ],
            ),
            body: Container(
              decoration: AppTheme.backgroundDecoration,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // Large EMF Dial Gauge
                      Center(
                        child: _buildEMFGauge(magnitude, statusColor, isDanger || isWarning),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // Status card
                      _buildStatusCard(statusText, statusIcon, statusColor),
                      
                      const SizedBox(height: 20),
                      
                      // Detailed breakdown
                      _buildBreakdownCard(magnitude, baseline, delta, statusColor),
                      
                      const SizedBox(height: 25),
                      
                      // Graph Title
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "REAL-TIME EMF WAVEFORM",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // EMF graph card
                      _buildGraphCard(state, isDanger),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEMFGauge(double value, Color color, bool isPulse) {
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.4),
        border: Border.all(color: color.withOpacity(0.3), width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isPulse ? 0.15 : 0.05),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_rounded, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            "µT (MICROTESLA)",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String text, IconData icon, Color color) {
    return GlassCard(
      borderSide: BorderSide(color: color.withOpacity(0.3), width: 1.2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(double mag, double base, double delta, Color color) {
    return GlassCard(
      child: Column(
        children: [
          _buildBreakdownRow("Magnetic Flux Magnitude", "${mag.toStringAsFixed(1)} µT", Colors.white),
          const Divider(color: AppColors.glassBorder, height: 24),
          _buildBreakdownRow("Dynamic Environmental Baseline", "${base.toStringAsFixed(1)} µT", AppColors.textSecondary),
          const Divider(color: AppColors.glassBorder, height: 24),
          _buildBreakdownRow(
            "Offset Delta (Deviation)", 
            "${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} µT", 
            color,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valColor,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGraphCard(MagneticState state, bool isDanger) {
    return GlassCard(
      child: Column(
        children: [
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: WaveGraphPainter(
                history: state.history.isEmpty ? [40, 42, 45, 41, 40, 44, 45, 46, 42, 40] : state.history,
                isSuspicious: isDanger,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SAMPLING RATE: 50Hz", style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
              Text("SWEEP DURATION: 10s", style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
            ],
          )
        ],
      ),
    );
  }
}
