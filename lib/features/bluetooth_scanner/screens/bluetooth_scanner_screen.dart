import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/bluetooth_bloc.dart';
import '../bloc/bluetooth_event.dart';
import '../bloc/bluetooth_state.dart';
import '../services/bluetooth_scanner_service.dart';
import '../widgets/bluetooth_widgets.dart';
import '../../../common/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class BluetoothScannerScreen extends StatefulWidget {
  const BluetoothScannerScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScannerScreen> createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends State<BluetoothScannerScreen> with TickerProviderStateMixin {
  late BluetoothBloc _bluetoothBloc;
  late AnimationController _concentricAnimController;
  late AnimationController _fluidWaveAnimController;

  @override
  void initState() {
    super.initState();
    _bluetoothBloc = BluetoothBloc()..add(StartBluetoothScan());

    _concentricAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fluidWaveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isGranted != true && 
        statuses[Permission.location]?.isGranted != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bluetooth & Location permissions are required for BLE scanner!"),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _concentricAnimController.dispose();
    _fluidWaveAnimController.dispose();
    _bluetoothBloc.add(StopBluetoothScan());
    _bluetoothBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bluetoothBloc,
      child: BlocListener<BluetoothBloc, BluetoothState>(
        listenWhen: (previous, current) =>
            previous.trackingDevice != current.trackingDevice ||
            previous.isScanning != current.isScanning,
        listener: (context, state) {
          final isTracking = state.trackingDevice != null;
          if (isTracking) {
            _concentricAnimController.stop();
            if (!_fluidWaveAnimController.isAnimating) {
              _fluidWaveAnimController.repeat();
            }
          } else {
            _fluidWaveAnimController.stop();
            if (state.isScanning) {
              if (!_concentricAnimController.isAnimating) {
                _concentricAnimController.repeat();
              }
            } else {
              _concentricAnimController.stop();
            }
          }
        },
        child: BlocBuilder<BluetoothBloc, BluetoothState>(
          builder: (context, state) {
            final isTracking = state.trackingDevice != null;

            return Scaffold(
              appBar: AppBar(
                title: Text(isTracking ? "SIGNAL LOCATOR" : "BLUETOOTH BLE SCANNER"),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () {
                    if (isTracking) {
                      context.read<BluetoothBloc>().add(StopTrackingDevice());
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                actions: [
                  if (!isTracking)
                    IconButton(
                      icon: Icon(
                        state.isScanning ? Icons.stop_circle : Icons.search_rounded,
                        color: state.isScanning ? AppColors.accentRed : AppColors.accentCyan,
                      ),
                      onPressed: () {
                        if (state.isScanning) {
                          context.read<BluetoothBloc>().add(StopBluetoothScan());
                        } else {
                          context.read<BluetoothBloc>().add(StartBluetoothScan());
                        }
                      },
                    )
                ],
              ),
              body: Container(
                decoration: AppTheme.backgroundDecoration,
                child: SafeArea(
                  child: isTracking 
                      ? _buildTrackingMode(context, state) 
                      : _buildScannerMode(context, state),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. SCANNER LIST MODE ---
  Widget _buildScannerMode(BuildContext context, BluetoothState state) {
    // Find strongest RSSI in discovered list
    int strongestRssi = -100;
    if (state.devices.isNotEmpty) {
      strongestRssi = state.devices.map((d) => d.rssi).reduce(max);
    }

    return Column(
      children: [
        // Concentric live meter
        Container(
          height: 160,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _concentricAnimController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 160),
                    painter: ConcentricSignalArcsPainter(
                      animationValue: _concentricAnimController.value,
                      maxRssi: strongestRssi,
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                child: Column(
                  children: [
                    Text(
                      state.isScanning ? "MONITORING BLE BEACONS..." : "SCANNER STANDBY",
                      style: TextStyle(
                        color: state.isScanning ? AppColors.accentCyan : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (state.isScanning && state.devices.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Strongest Signal: $strongestRssi dBm",
                        style: TextStyle(
                          color: strongestRssi >= -50 ? AppColors.accentRed : AppColors.accentCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        if (state.isScanning)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(
              minHeight: 2.0,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
            ),
          ),

        // Device List Section
        Expanded(
          child: state.devices.isEmpty
              ? _buildEmptyState(state)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: state.devices.length,
                  itemBuilder: (context, index) {
                    final device = state.devices[index];
                    return _buildDeviceListItem(context, device);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BluetoothState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled_rounded,
            color: AppColors.textMuted.withOpacity(0.3),
            size: 60,
          ),
          const SizedBox(height: 12),
          Text(
            state.isScanning ? "Searching for signals..." : "Scanner Offline",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            state.isScanning 
                ? "Move around the room slowly" 
                : "Tap scan button to search nearby BLE nodes",
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListItem(BuildContext context, BleDeviceResult device) {
    final bool isDanger = device.isSuspicious;
    
    // Choose progress bar color and text values
    Color signalColor;
    if (device.rssi >= -50) {
      signalColor = AppColors.accentRed;
    } else if (device.rssi >= -75) {
      signalColor = AppColors.warningOrange;
    } else {
      signalColor = AppColors.successGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderSide: BorderSide(
          color: isDanger ? AppColors.accentRed.withOpacity(0.3) : AppColors.glassBorder,
          width: 1.2,
        ),
        fillCol: isDanger ? AppColors.accentRed.withOpacity(0.03) : null,
        child: Row(
          children: [
            // Custom BLE Icon with glow
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDanger ? Icons.warning_rounded : Icons.bluetooth_rounded,
                color: signalColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(
                      color: isDanger ? AppColors.accentRed : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "MAC: ${device.deviceId}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 8),

                  // Real-time animated progress bar using TweenAnimationBuilder
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween<double>(
                              begin: 0.0,
                              end: ((device.rssi + 100) / 60.0).clamp(0.01, 1.0),
                            ),
                            builder: (context, val, child) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 5,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  Container(
                                    height: 5,
                                    width: MediaQuery.of(context).size.width * 0.45 * val,
                                    decoration: BoxDecoration(
                                      color: signalColor,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: signalColor.withOpacity(0.4),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${device.rssi} dBm",
                        style: TextStyle(
                          color: signalColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Locate Action Button (glowing for suspicious devices, normal otherwise)
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.radar_rounded,
                color: isDanger ? AppColors.accentRed : AppColors.accentCyan,
                size: 24,
              ),
              onPressed: () {
                context.read<BluetoothBloc>().add(StartTrackingDevice(device));
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. DYNAMIC HOT-COLD TRACKING MODE ---
  Widget _buildTrackingMode(BuildContext context, BluetoothState state) {
    final device = state.trackingDevice!;
    final proximity = state.proximityScore;
    
    // Choose status name based on proximity
    String distanceStatus = "COLD";
    Color statusColor = AppColors.accentCyan;
    if (proximity > 75) {
      distanceStatus = "CRITICAL PROXIMITY!";
      statusColor = AppColors.accentRed;
    } else if (proximity > 45) {
      distanceStatus = "WARM";
      statusColor = AppColors.warningOrange;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Info of device being tracked
          GlassCard(
            borderSide: BorderSide(color: statusColor.withOpacity(0.3), width: 1.2),
            child: Row(
              children: [
                Icon(Icons.track_changes_rounded, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "MAC: ${device.deviceId} | RSSI: ${device.rssi} dBm",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // Fluid Wave radar circular zone
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animating fluid waves
                  AnimatedBuilder(
                    animation: _fluidWaveAnimController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(250, 250),
                        painter: FluidWavePainter(
                          animationValue: _fluidWaveAnimController.value,
                          proximityScore: proximity,
                        ),
                      );
                    },
                  ),
                  
                  // Score text inside core
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                      border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.15),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$proximity%",
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "PROXIMITY",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Status & guidance prompt
          Text(
            distanceStatus,
            style: TextStyle(
              color: statusColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            proximity > 75 
                ? "Extreme signal magnitude! Check outlets, clock widgets, and smoke detectors in your immediate reach."
                : (proximity > 45 
                    ? "Getting warmer. Walk in different directions to trace if the signal continues rising."
                    : "Signal is faint. Check other areas of the room."),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 30),

          // Simulator debugging buttons to test Hot-Cold Mode
          Text(
            "TEST EMULATOR CONTROLS",
            style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2.0),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.remove, color: AppColors.accentCyan),
                onPressed: () {
                  int currentRssi = device.rssi;
                  int nextRssi = (currentRssi - 5).clamp(-100, -40);
                  context.read<BluetoothBloc>().add(UpdateTrackingRssi(nextRssi));
                },
              ),
              const SizedBox(width: 20),
              IconButton.outlined(
                icon: const Icon(Icons.add, color: AppColors.accentRed),
                onPressed: () {
                  int currentRssi = device.rssi;
                  int nextRssi = (currentRssi + 5).clamp(-100, -40);
                  context.read<BluetoothBloc>().add(UpdateTrackingRssi(nextRssi));
                },
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Cancel tracking button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                context.read<BluetoothBloc>().add(StopTrackingDevice());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
                ),
              ),
              child: const Text(
                "STOP TRACKING",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
