import 'package:flutter/foundation.dart';
import '../../../common/models/scan_report.dart';

@immutable
abstract class RadarEvent {}

class StartRadarScan extends RadarEvent {}

class StopRadarScan extends RadarEvent {}

class UpdateRadarProgress extends RadarEvent {
  final double progress;
  final String statusText;
  UpdateRadarProgress(this.progress, this.statusText);
}

class CompleteRadarScan extends RadarEvent {
  final ScanReport report;
  CompleteRadarScan(this.report);
}
