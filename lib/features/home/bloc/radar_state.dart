import 'package:flutter/foundation.dart';
import '../../../common/models/scan_report.dart';

@immutable
abstract class RadarState {}

class RadarIdle extends RadarState {}

class RadarScanning extends RadarState {
  final double progress;
  final String statusText;

  RadarScanning({required this.progress, required this.statusText});
}

class RadarSuccess extends RadarState {
  final ScanReport report;

  RadarSuccess({required this.report});
}

class RadarFailure extends RadarState {
  final String error;

  RadarFailure({required this.error});
}
