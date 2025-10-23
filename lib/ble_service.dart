import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ESP32BLEService {
  // ESP32 的 UUID 設定（與您的 ESP32 程式碼一致）
  static const String serviceUUID = "12345678-1234-5678-1234-56789abcdef0";
  static const String cmdCharUUID = "12345678-1234-5678-1234-56789abcdef1";
  static const String statCharUUID = "12345678-1234-5678-1234-56789abcdef2";
  static const String targetDeviceName = "ESP32_XYZ_Table";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? cmdCharacteristic;
  BluetoothCharacteristic? statCharacteristic;

  // 狀態更新串流
  final StreamController<String> _statusStreamController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusStreamController.stream;

  // 掃描裝置
  Stream<List<ScanResult>> scanForDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    return FlutterBluePlus.scanResults;
  }

  // 停止掃描
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // 連接到 ESP32
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice = device;

      // 發現服務
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();

            if (charUuid == cmdCharUUID.toLowerCase()) {
              cmdCharacteristic = characteristic;
            } else if (charUuid == statCharUUID.toLowerCase()) {
              statCharacteristic = characteristic;

              // 訂閱狀態通知
              await statCharacteristic!.setNotifyValue(true);
              statCharacteristic!.lastValueStream.listen((value) {
                String status = String.fromCharCodes(value);
                _statusStreamController.add(status);
              });
            }
          }
        }
      }

      return cmdCharacteristic != null && statCharacteristic != null;
    } catch (e) {
      print('連接失敗: $e');
      return false;
    }
  }

  // 斷開連接
  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
    cmdCharacteristic = null;
    statCharacteristic = null;
  }

  // 發送指令到 ESP32
  Future<void> sendCommand(String command) async {
    if (cmdCharacteristic != null) {
      await cmdCharacteristic!.write(command.codeUnits, withoutResponse: false);
    }
  }

  // 切換到絕對模式
  Future<void> setAbsoluteMode() async {
    await sendCommand('@,ABS');
  }

  // 切換到相對模式
  Future<void> setRelativeMode() async {
    await sendCommand('@,REL');
  }

  // 移動 X 軸
  Future<void> moveX(int distance, int speed) async {
    await sendCommand('@,X,$distance,$speed,!');
  }

  // 移動 Y 軸
  Future<void> moveY(int distance, int speed) async {
    await sendCommand('@,Y,$distance,$speed,!');
  }

  // 移動 Z 軸
  Future<void> moveZ(int distance, int speed) async {
    await sendCommand('@,Z,$distance,$speed,!');
  }

  // 檢查是否已連接
  bool get isConnected => connectedDevice != null;

  // 清理資源
  void dispose() {
    _statusStreamController.close();
  }
}
