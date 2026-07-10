import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'lan_event.dart';
import 'lan_state.dart';
import '../services/network_scanner_service.dart';
import '../../../common/models/discovered_device.dart';

class LanBloc extends Bloc<LanEvent, LanState> {
  final NetworkInfo _networkInfo = NetworkInfo();
  final NetworkScannerService _scannerService = NetworkScannerService();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  LanBloc() : super(LanState.initial()) {
    on<FetchLanNetworkInfo>(_onFetchNetworkInfo);
    on<StartLanScan>(_onStartScan);
    on<StopLanScan>(_onStopScan);
    on<LanDeviceDiscovered>(_onDeviceDiscovered);
    on<CompleteLanScan>(_onCompleteScan);
    on<LanScanError>(_onScanError);
  }

  Future<void> _onFetchNetworkInfo(FetchLanNetworkInfo event, Emitter<LanState> emit) async {
    try {
      await Permission.location.request();
      final wifiName = await _networkInfo.getWifiName();
      final myIp = await _networkInfo.getWifiIP();
      final subnetMask = await _networkInfo.getWifiSubmask();
      
      emit(state.copyWith(
        wifiName: wifiName ?? "Unknown WiFi",
        myIp: myIp,
        subnetMask: subnetMask,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: "Failed to load network info: $e"));
    }
  }

  void _onStartScan(StartLanScan event, Emitter<LanState> emit) {
    if (state.myIp == null || state.subnetMask == null) {
      emit(state.copyWith(error: "Network info not available. Please connect to WiFi."));
      return;
    }

    _scanSubscription?.cancel();
    emit(state.copyWith(isScanning: true, devices: [], error: null));

    _scanSubscription = _scannerService.scanNetworkForCameras(state.myIp!, state.subnetMask!).listen(
      (device) {
        add(LanDeviceDiscovered(device));
      },
      onDone: () {
        add(CompleteLanScan());
      },
      onError: (e) {
        add(LanScanError(e.toString()));
      }
    );
  }

  void _onStopScan(StopLanScan event, Emitter<LanState> emit) {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    emit(state.copyWith(isScanning: false));
  }

  void _onDeviceDiscovered(LanDeviceDiscovered event, Emitter<LanState> emit) {
    final currentDevices = List<DiscoveredDevice>.from(state.devices);
    // Avoid duplicates
    if (!currentDevices.any((d) => d.ip == event.device.ip)) {
      currentDevices.add(event.device);
    }
    emit(state.copyWith(devices: currentDevices));
  }

  void _onCompleteScan(CompleteLanScan event, Emitter<LanState> emit) {
    _scanSubscription = null;
    emit(state.copyWith(isScanning: false));
  }

  void _onScanError(LanScanError event, Emitter<LanState> emit) {
    _scanSubscription = null;
    emit(state.copyWith(isScanning: false, error: event.error));
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }
}
