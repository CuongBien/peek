import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SensorExample(),
    );
  }
}

class SensorExample extends StatefulWidget {
  @override
  _SensorExampleState createState() => _SensorExampleState();
}

class _SensorExampleState extends State<SensorExample> {
  List<double>? _accelerometerValues;
  List<double>? _userAccelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    // 1. Lắng nghe Accelerometer
    _streamSubscriptions.add(
      accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Lỗi"),
                content: Text("Không tìm thấy cảm biến này trên thiết bị"),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
    // 2. Lắng nghe User Accelerometer
    _streamSubscriptions.add(
      userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
        setState(() {
          _userAccelerometerValues = <double>[event.x, event.y, event.z];
        });
      }),
    );
    // 3. Lắng nghe Gyroscope
    _streamSubscriptions.add(
      gyroscopeEventStream().listen((GyroscopeEvent event) {
        setState(() {
          _gyroscopeValues = <double>[event.x, event.y, event.z];
        });
      }),
    );
    // 4. Lắng nghe Magnetometer
    _streamSubscriptions.add(
      magnetometerEventStream().listen((MagnetometerEvent event) {
        double x = event.x;
        double y = event.y;
        double z = event.z;

        double magnitude = sqrt((x * x) + (y * y) + (z * z));
        setState(() {
          _magnetometerValues = <double>[x, y, z];
          print("Độ lớn từ trường: ${magnitude.toStringAsFixed(2)} µT");
        });
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper function để định dạng output
    final accelerometer = _accelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    final gyroscope = _gyroscopeValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    final magnetometer = _magnetometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Plus')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Accelerometer: $accelerometer'),
            const SizedBox(height: 16),
            Text('UserAccelerometer: $userAccelerometer'),
            const SizedBox(height: 16),
            Text('Gyroscope: $gyroscope'),
            const SizedBox(height: 16),
            Text('Magnetometer: $magnetometer'),
          ],
        ),
      ),
    );
  }
}
