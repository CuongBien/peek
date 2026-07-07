import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:rxdart/rxdart.dart';
import '../../../common/models/magnetic_result.dart';

class MagneticDetectionService {
  // --- Cấu hình thuật toán DSP ---
  final double _alphaSmooth = 0.2;     // LPF cho tín hiệu nhanh (0.1 - 0.3)
  final double _alphaBaseline = 0.002; // Giảm mạnh Alpha để baseline bám rất chậm
  
  // --- Ngưỡng cảnh báo (Thresholds) tính theo microtesla ---
  final double _warningThreshold = 15.0; // Lệch 15 µT so với nền
  final double _dangerThreshold = 35.0;  // Lệch 35 µT so với nền

  // --- Biến trạng thái State ---
  double? _smoothedValue;
  double? _baselineValue;

  // --- Streams ---
  StreamSubscription<MagnetometerEvent>? _sensorSubscription;
  
  // Dùng BehaviorSubject từ rxdart để luôn giữ giá trị mới nhất cho UI
  final _resultController = BehaviorSubject<MagneticResult>();
  Stream<MagneticResult> get resultStream => _resultController.stream;

  /// Bắt đầu lắng nghe và xử lý dữ liệu cảm biến
  void startScanning() {
    if (_sensorSubscription != null) return;

    // Lắng nghe dữ liệu thô từ phần cứng
    final rawStream = magnetometerEventStream();

    _sensorSubscription = rawStream.listen((MagnetometerEvent event) {
      _processSensorData(event.x, event.y, event.z);
    });
  }

  /// Hàm xử lý tín hiệu DSP (Chạy liên tục ở 50Hz-100Hz)
  void _processSensorData(double x, double y, double z) {
    // 1. Tính độ lớn tổng hợp của Vector
    final rawMagnitude = sqrt(x * x + y * y + z * z);

    // Khởi tạo giá trị ban đầu nếu là lần chạy đầu tiên
    if (_smoothedValue == null || _baselineValue == null) {
      _smoothedValue = rawMagnitude;
      _baselineValue = rawMagnitude;
      return; // Bỏ qua frame đầu tiên
    }

    // 2. Lọc thông thấp (Low-pass Filter) để khử nhiễu (Smooth Data)
    _smoothedValue = _alphaSmooth * rawMagnitude + (1 - _alphaSmooth) * _smoothedValue!;

    // 3. Tính toán độ lệch (Delta) tạm thời
    final delta = (_smoothedValue! - _baselineValue!).abs();

    // 4. Cập nhật Đường cơ sở động (Dynamic Baseline)
    // CẢI TIẾN: Nếu đang phát hiện từ trường mạnh (vượt ngưỡng cảnh báo),
    // chúng ta sẽ KHÔNG cập nhật baseline. Nếu cập nhật lúc này, baseline sẽ bị
    // "kéo" theo nam châm, làm app tưởng nam châm là môi trường bình thường.
    if (delta < _warningThreshold) {
      _baselineValue = _alphaBaseline * _smoothedValue! + (1 - _alphaBaseline) * _baselineValue!;
    }

    // 5. Đối chiếu với Ngưỡng tự động (Adaptive Threshold)
    MagneticStatus currentStatus = MagneticStatus.normal;
    if (delta >= _dangerThreshold) {
      currentStatus = MagneticStatus.danger;
    } else if (delta >= _warningThreshold) {
      currentStatus = MagneticStatus.warning;
    }

    // 6. Đẩy kết quả vào Controller
    // LƯU Ý: Ở đây ta đẩy dữ liệu liên tục. Việc Throttle sẽ được thực hiện ở đầu ra.
    _resultController.add(
      MagneticResult(
        magnitude: _smoothedValue!,
        baseline: _baselineValue!,
        delta: delta,
        status: currentStatus,
      ),
    );
  }

  /// Trả về một luồng đã được tối ưu hóa (Throttle) để bind lên UI
  /// Tránh việc UI phải rebuild hàng trăm lần mỗi giây gây lag máy
  Stream<MagneticResult> getOptimizedUIStream({Duration throttleDuration = const Duration(milliseconds: 100)}) {
    return _resultController.stream.throttleTime(
      throttleDuration, 
      trailing: true, // Đảm bảo lấy giá trị mới nhất ở cuối chu kỳ
    );
  }

  /// Reset thủ công Baseline (Dùng khi UI có nút "Hiệu chuẩn lại / Recalibrate")
  void recalibrate() {
    if (_smoothedValue != null) {
      _baselineValue = _smoothedValue;
    }
  }

  /// Dọn dẹp bộ nhớ (Chống Memory Leak)
  void dispose() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _resultController.close();
  }
}
