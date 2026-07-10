import 'package:flutter/foundation.dart';
import '../../../common/models/magnetic_result.dart';

@immutable
abstract class MagneticEvent {}

class StartMagneticTracking extends MagneticEvent {}

class StopMagneticTracking extends MagneticEvent {}

class MagneticDataUpdated extends MagneticEvent {
  final MagneticResult result;
  MagneticDataUpdated(this.result);
}

class RecalibrateMagnetic extends MagneticEvent {}
