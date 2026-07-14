# Peek: Hidden Camera & Spy Device Detector

Peek is a premium, feature-rich mobile security application built with Flutter. It is designed to safeguard user privacy by scanning and detecting hidden surveillance equipment—such as spy cameras, wireless microphones, tracking beacons, and unauthorized network devices—using advanced hardware sensors and network protocols.

The application is structured using **Feature-First / Clean Architecture** principles and managed with the **BLoC (Business Logic Component)** pattern for maximum modularity, clean state management, and scalability.

---

## 📸 Screenshots

| Dashboard & Radar | WiFi Subnet Scanner | BLE Proximity Detector | Camera Lens Finder |
|:---:|:---:|:---:|:---:|
| `<!-- TODO: Add Dashboard Screenshot Here -->` | `<!-- TODO: Add WiFi Scan Screenshot Here -->` | `<!-- TODO: Add BLE Scan Screenshot Here -->` | `<!-- TODO: Add Lens Finder Screenshot Here -->` |

| Magnetic Detector | Scan Report & Analytics |
|:---:|:---:|
| `<!-- TODO: Add EMF Scan Screenshot Here -->` | `<!-- TODO: Add Report Screenshot Here -->` |

---

## ✨ Features

Peek integrates four primary scanning methodologies to provide comprehensive protection:

### 1. 🌀 Environment Radar Scan (Main Hub)
* Coordinates and triggers all scanning subsystems (WiFi, BLE, Magnetometer) simultaneously.
* Displays a real-time animated custom radar sweep using Flutter's `CustomPainter` (`RadarPainter`).
* Compiles results into a cohesive **Scan Report** containing severity scores (Safe, Warning, Danger) and an actionable threat list.

### 2. 🧲 EMF (Electro-Magnetic Field) Detection
* Interacts with the phone's physical magnetometer sensor to measure magnetic flux.
* Utilizes a **Digital Signal Processing (DSP) Low-Pass Filter (LPF)** to filter hardware noise and smooth raw signals.
* Employs an **adaptive baseline tracking algorithm** that freezes baseline updates during anomalies to prevent "baseline drift" when close to magnetic sources.

### 3. 🌐 Local Network (WiFi) Scanner
* Retrieves Wi-Fi details (SSID, Subnet Mask, Local IP) and calculates the local subnet IP address range.
* Initiates parallel socket-level TCP port scanning with **batch size limiting** (scans 5 IPs at a time with brief pauses) to prevent Event Loop choke and Android ANR (Application Not Responding) crashes.
* Scans crucial camera ports: `554 (RTSP)`, `80 (HTTP)`, `8080`, and `8000 (SDK/Data)`.
* Performs **Device Fingerprinting** by sending raw HTTP GET and RTSP OPTIONS probes to parse `Server` headers, letting users identify device manufacturers (e.g., Hikvision, Dahua) without needing root-level MAC address access.

### 4. 📶 Bluetooth Low Energy (BLE) Scanner
* Continuously scans for nearby BLE advertisement signals.
* Filters and flags **unnamed devices (Unnamed Beacons)**, which are commonly utilized by cheap spy camera modules to avoid detection.
* Uses **RSSI (Received Signal Strength Indicator)** tracking to estimate physical proximity. Alerts the user with a distinct warning when a suspicious beacon is within immediate reach (`RSSI >= -50 dBm`).

### 5. 📷 Optical Camera Lens Finder
* Renders a real-time camera viewfinder stream.
* Overlays specialized visual guides, pulsing corner brackets, and scanning laser line animations.
* Assists the user in manually locating hidden camera lenses via infrared glints or light reflections.

---

## 🛠️ Architecture & Tech Stack

The project follows a modular, feature-oriented structure:

```text
lib/
├── common/
│   ├── models/            # Shared data models (e.g. ScanReport, DiscoveredDevice)
│   └── widgets/           # Global design widgets (e.g. GlassCard)
├── core/
│   └── theme/             # Global visual tokens, gradients, and custom AppColors
└── features/              # Modular feature folders containing screen UI, services, and BLoCs
    ├── home/              # Main dashboard navigation, radar UI, and results
    ├── lan_scanner/       # Subnet scanner logic, port probes, and WiFi UI
    ├── bluetooth_scanner/ # BLE scans, RSSI indicator, and BLE scanner UI
    └── magnetic_detector/ # Magnetometer DSP, calibration, and EMF UI
```

### Key Libraries Used:
* **State Management**: `flutter_bloc` (v9.1.1+) & `rxdart` (reactive stream operators).
* **Hardware Interactivity**: `sensors_plus` (Magnetometer) & `camera` (Lens Finder).
* **Network & Wireless**: `network_info_plus` & `flutter_blue_plus` (BLE Scans).
* **Permissions**: `permission_handler` (Gracefully manages Location, Bluetooth, and Camera permissions).

---

## 🚀 Getting Started & Installation

### Prerequisites
* Flutter SDK: `^3.11.5` or higher.
* Android SDK (minimum API level 21, API level 33+ recommended for BLE permissions).
* Physical Device: Accessing the camera, BLE, and magnetometer requires a physical Android or iOS device. (Features will fallback to mock data on emulators).

### Setup Instructions

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/biencaocuongg/peek.git
   cd peek
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Permissions (Native Android):**
   The application already contains configuration for Android permissions in `android/app/src/main/AndroidManifest.xml`. Ensure the following permissions are present:
   * Location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) - Needed for WiFi SSID and BLE scanning.
   * Bluetooth (`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`).
   * Camera (`CAMERA`).

4. **Run the Application:**
   Connect your physical device via USB Debugging and run:
   ```bash
   flutter run
   ```

---

## ⚙️ Development & Testing

To analyze the codebase for lint issues and style rules:
```bash
flutter analyze
```

To run built-in unit or widget tests:
```bash
flutter test
```

---

## 📄 License

This project is proprietary and confidential. All rights reserved.
