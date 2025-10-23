import 'package:flutter/material.dart';
import 'ble_service.dart';

class ControlPage extends StatefulWidget {
  final ESP32BLEService bleService;

  const ControlPage({super.key, required this.bleService});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  String status = '等待連接...';
  bool isAbsoluteMode = false;

  // 軸位置
  int xPos = 0;
  int yPos = 0;
  int zPos = 0;

  // 控制參數
  final TextEditingController xDistController = TextEditingController(text: '1000');
  final TextEditingController yDistController = TextEditingController(text: '1000');
  final TextEditingController zDistController = TextEditingController(text: '1000');
  final TextEditingController speedController = TextEditingController(text: '200');

  @override
  void initState() {
    super.initState();
    // 監聽狀態更新
    widget.bleService.statusStream.listen((statusMsg) {
      setState(() {
        status = statusMsg;
        // 解析位置資訊: "X:123 Y:456 Z:789"
        _parsePosition(statusMsg);
      });
    });
  }

  // 解析位置資訊
  void _parsePosition(String msg) {
    try {
      final parts = msg.split(' ');
      for (var part in parts) {
        if (part.startsWith('X:')) {
          xPos = int.parse(part.substring(2));
        } else if (part.startsWith('Y:')) {
          yPos = int.parse(part.substring(2));
        } else if (part.startsWith('Z:')) {
          zPos = int.parse(part.substring(2));
        }
      }
    } catch (e) {
      // 忽略解析錯誤
    }
  }

  // 切換模式
  Future<void> _toggleMode() async {
    if (isAbsoluteMode) {
      await widget.bleService.setRelativeMode();
    } else {
      await widget.bleService.setAbsoluteMode();
    }
    setState(() {
      isAbsoluteMode = !isAbsoluteMode;
    });
  }

  // 移動軸
  Future<void> _moveAxis(String axis) async {
    int distance = 0;
    int speed = int.tryParse(speedController.text) ?? 200;

    switch (axis) {
      case 'X':
        distance = int.tryParse(xDistController.text) ?? 0;
        await widget.bleService.moveX(distance, speed);
        break;
      case 'Y':
        distance = int.tryParse(yDistController.text) ?? 0;
        await widget.bleService.moveY(distance, speed);
        break;
      case 'Z':
        distance = int.tryParse(zDistController.text) ?? 0;
        await widget.bleService.moveZ(distance, speed);
        break;
    }
  }

  // 快速移動按鈕
  Widget _quickMoveButton(String axis, int distance) {
    return ElevatedButton(
      onPressed: () async {
        int speed = int.tryParse(speedController.text) ?? 200;
        switch (axis) {
          case 'X':
            await widget.bleService.moveX(distance, speed);
            break;
          case 'Y':
            await widget.bleService.moveY(distance, speed);
            break;
          case 'Z':
            await widget.bleService.moveZ(distance, speed);
            break;
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: distance > 0 ? Colors.green : Colors.orange,
      ),
      child: Text(distance > 0 ? '+$distance' : '$distance'),
    );
  }

  // 軸控制面板
  Widget _axisControlPanel(String axis, TextEditingController controller, int position) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$axis 軸',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '當前位置: $position',
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '移動距離',
                      border: const OutlineInputBorder(),
                      suffixText: 'steps',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _moveAxis(axis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Text('移動'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickMoveButton(axis, -1000),
                _quickMoveButton(axis, -100),
                _quickMoveButton(axis, 100),
                _quickMoveButton(axis, 1000),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 XYZ 控制台'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () async {
              await widget.bleService.disconnect();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 狀態顯示
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        '連接狀態',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 模式切換
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '移動模式',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            isAbsoluteMode ? '絕對模式' : '相對模式',
                            style: TextStyle(
                              fontSize: 16,
                              color: isAbsoluteMode ? Colors.purple : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isAbsoluteMode,
                            onChanged: (value) => _toggleMode(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 速度設定
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        '移動速度',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: speedController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            suffixText: 'μs/step',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // X 軸控制
              _axisControlPanel('X', xDistController, xPos),

              // Y 軸控制
              _axisControlPanel('Y', yDistController, yPos),

              // Z 軸控制
              _axisControlPanel('Z', zDistController, zPos),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    xDistController.dispose();
    yDistController.dispose();
    zDistController.dispose();
    speedController.dispose();
    super.dispose();
  }
}
