import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_screen.dart';
import 'camera_scan_screen.dart';
import '../../lan_scanner/screens/lan_scanner_screen.dart';
import '../../bluetooth_scanner/screens/bluetooth_scanner_screen.dart';
import '../../magnetic_detector/screens/magnetic_detector_screen.dart';
import '../bloc/radar_bloc.dart';
import '../../lan_scanner/bloc/lan_bloc.dart';
import '../../lan_scanner/bloc/lan_event.dart';
import '../../bluetooth_scanner/bloc/bluetooth_bloc.dart';
import '../../magnetic_detector/bloc/magnetic_bloc.dart';
import '../../magnetic_detector/bloc/magnetic_event.dart';
import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/glass_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Dynamic screens list to manage camera initialization reactively
    final List<Widget> screens = [
      const DashboardScreen(),
      const LanScannerScreen(),
      const BluetoothScannerScreen(),
      CameraScanScreen(isCameraActive: _currentIndex == 3),
      const MagneticDetectorScreen(),
    ];

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => RadarBloc()),
        BlocProvider(create: (context) => LanBloc()..add(FetchLanNetworkInfo())),
        BlocProvider(create: (context) => BluetoothBloc()),
        BlocProvider(create: (context) => MagneticBloc()..add(StartMagneticTracking())),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundEnd,
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x0A007AFF),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GlassCard(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                blur: 20,
                borderSide: const BorderSide(color: AppColors.glassBorder, width: 1.0),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  type: BottomNavigationBarType.fixed, // Support 5 items nicely
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.radar_rounded),
                      activeIcon: Icon(Icons.radar_rounded, color: AppColors.accentBlue),
                      label: 'Radar',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.wifi_find_rounded),
                      activeIcon: Icon(Icons.wifi_find_rounded, color: AppColors.accentBlue),
                      label: 'WiFi Scan',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bluetooth_searching_rounded),
                      activeIcon: Icon(Icons.bluetooth_searching_rounded, color: AppColors.accentBlue),
                      label: 'BLE Scan',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.videocam_outlined),
                      activeIcon: Icon(Icons.videocam_rounded, color: AppColors.accentBlue),
                      label: 'Lens Finder',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.explore_outlined),
                      activeIcon: Icon(Icons.explore_rounded, color: AppColors.accentBlue),
                      label: 'EMF Log',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
