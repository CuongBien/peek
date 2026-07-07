enum MagneticStatus { normal, warning, danger }

class MagneticResult {
  final double magnitude;
  final double baseline;
  final double delta;
  final MagneticStatus status;

  MagneticResult({
    required this.magnitude,
    required this.baseline,
    required this.delta,
    required this.status,
  });
}
