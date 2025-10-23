import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_service.dart';
import 'control_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ESP32BLEService bleService = ESP32BLEService();
  bool isScanning = false;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // 檢查並請求權限
  Future<void> _checkPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  // 開始掃描
  void _startScan() {
    setState(() {
      isScanning = true;
    });
    bleService.scanForDevices();
  }

  // 停止掃描
  void _stopScan() {
    bleService.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  // 連接到設備
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    bool success = await bleService.connect(device);

    setState(() {
      isConnecting = false;
    });

    if (success && mounted) {
      _stopScan();
      // 導航到控制頁面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ControlPage(bleService: bleService),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('連接失敗，請重試')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描 ESP32 設備'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isScanning ? _stopScan : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning ? Colors.red : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isScanning ? '停止掃描' : '開始掃描',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          if (isConnecting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: bleService.scanForDevices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      '未找到設備\n請確認 ESP32 已開啟',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                List<ScanResult> results = snapshot.data!;

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    ScanResult result = results[index];
                    String deviceName = result.device.platformName;
                    String deviceId = result.device.remoteId.toString();
                    int rssi = result.rssi;

                    // 只顯示有名稱的設備
                    if (deviceName.isEmpty) {
                      deviceName = '未知設備';
                    }

                    // 標記目標設備
                    bool isTargetDevice = deviceName == ESP32BLEService.targetDeviceName;

                    return Card(
                      color: isTargetDevice ? Colors.blue.shade50 : null,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isTargetDevice ? Colors.blue : Colors.grey,
                          size: 40,
                        ),
                        title: Text(
                          deviceName,
                          style: TextStyle(
                            fontWeight: isTargetDevice ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('$deviceId\n信號強度: $rssi dBm'),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(result.device),
                          child: const Text('連接'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }
}
