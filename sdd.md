# 軟體設計文件 (Software Design Document)

**最後更新時間**: 2025-10-23

**下一步計劃**:
1. 根據實機測試結果調整架構
2. 評估是否需要新增錯誤處理機制
3. 根據使用者回饋優化 UI/UX

---

## 1. 專案概述

### 1.1 專案名稱
ESP32 XYZ 控制台 APP (ESP32 XYZ Table Control App)

### 1.2 專案目標
開發一個跨平台的 Flutter 行動應用程式，透過藍芽 BLE (Bluetooth Low Energy) 連接 ESP32 微控制器，實現對 XYZ 三軸步進馬達的無線控制。

### 1.3 目標平台
- Android (API Level 21+, Android 5.0+)
- iOS (iOS 12.0+)

### 1.4 開發語言與框架
- **語言**: Dart 3.0+
- **框架**: Flutter 3.0+
- **主要套件**:
  - flutter_blue_plus: ^1.32.0 (BLE 通訊)
  - permission_handler: ^11.0.1 (權限管理)

---

## 2. 系統架構

### 2.1 整體架構圖

```
┌─────────────────────────────────────────────────┐
│                  Flutter APP                    │
│  ┌───────────────────────────────────────────┐  │
│  │           Presentation Layer              │  │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────┐ │  │
│  │  │ScanPage  │  │ControlPage│  │main.dart│ │  │
│  │  └──────────┘  └──────────┘  └─────────┘ │  │
│  └───────────────────────────────────────────┘  │
│                      ↕                          │
│  ┌───────────────────────────────────────────┐  │
│  │           Business Logic Layer            │  │
│  │         ┌──────────────────┐              │  │
│  │         │  BLE Service     │              │  │
│  │         │  (ble_service.dart)│            │  │
│  │         └──────────────────┘              │  │
│  └───────────────────────────────────────────┘  │
│                      ↕                          │
│  ┌───────────────────────────────────────────┐  │
│  │           Data Access Layer               │  │
│  │         ┌──────────────────┐              │  │
│  │         │flutter_blue_plus │              │  │
│  │         │   (BLE Plugin)   │              │  │
│  │         └──────────────────┘              │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                      ↕ BLE
┌─────────────────────────────────────────────────┐
│                   ESP32                         │
│  ┌───────────────────────────────────────────┐  │
│  │         BLE Server (GATT)                 │  │
│  │  Service: 12345678-1234-5678-1234-...def0 │  │
│  │  ├─ Cmd:  ...def1 (Write)                 │  │
│  │  └─ Stat: ...def2 (Read/Notify)           │  │
│  └───────────────────────────────────────────┘  │
│                      ↕                          │
│  ┌───────────────────────────────────────────┐  │
│  │         Motor Control Logic               │  │
│  │  ┌──────┐  ┌──────┐  ┌──────┐             │  │
│  │  │ X軸  │  │ Y軸  │  │ Z軸  │             │  │
│  │  └──────┘  └──────┘  └──────┘             │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 2.2 分層架構說明

#### 2.2.1 Presentation Layer (展示層)
- **職責**: 處理使用者介面和使用者互動
- **元件**:
  - `main.dart`: APP 入口點
  - `scan_page.dart`: 裝置掃描和連接頁面
  - `control_page.dart`: 軸控制介面

#### 2.2.2 Business Logic Layer (業務邏輯層)
- **職責**: 處理業務邏輯和 BLE 通訊協定
- **元件**:
  - `ble_service.dart`: BLE 連接管理、指令封裝、狀態解析

#### 2.2.3 Data Access Layer (資料存取層)
- **職責**: 提供底層 BLE 通訊能力
- **元件**:
  - `flutter_blue_plus`: Flutter 的 BLE 插件

---

## 3. 資料流設計

### 3.1 掃描裝置流程

```
User Action → ScanPage → BLEService → flutter_blue_plus → ESP32
    ↓
[點擊掃描]
    ↓
startScan()
    ↓
FlutterBluePlus.startScan()
    ↓
[接收掃描結果串流]
    ↓
Stream<List<ScanResult>>
    ↓
[顯示裝置列表]
```

### 3.2 連接裝置流程

```
User Action → ScanPage → BLEService → ESP32
    ↓
[點擊連接]
    ↓
connect(device)
    ↓
device.connect()
    ↓
discoverServices()
    ↓
[找到 Service UUID]
    ↓
[找到 Characteristics]
    ↓
setNotifyValue(true) for Status Characteristic
    ↓
[訂閱狀態通知]
    ↓
Navigator.push(ControlPage)
```

### 3.3 發送指令流程

```
User Action → ControlPage → BLEService → ESP32
    ↓
[點擊移動按鈕]
    ↓
moveX(distance, speed)
    ↓
sendCommand('@,X,1000,200,!')
    ↓
cmdCharacteristic.write(command)
    ↓
[ESP32 接收並執行]
```

### 3.4 接收狀態流程

```
ESP32 → BLEService → ControlPage → UI Update
    ↓
[ESP32 發送通知]
    ↓
statCharacteristic.notify()
    ↓
lastValueStream.listen()
    ↓
_statusStreamController.add(status)
    ↓
statusStream.listen()
    ↓
setState() → [更新 UI]
```

---

## 4. 通訊協定設計

### 4.1 BLE GATT 服務結構

```
Service: 12345678-1234-5678-1234-56789abcdef0
│
├─ Characteristic (Command): 12345678-1234-5678-1234-56789abcdef1
│  ├─ Properties: WRITE
│  └─ Function: 接收來自 APP 的控制指令
│
└─ Characteristic (Status): 12345678-1234-5678-1234-56789abcdef2
   ├─ Properties: READ, NOTIFY
   └─ Function: 發送狀態更新到 APP
```

### 4.2 指令格式規範

#### 4.2.1 模式切換指令

| 功能 | 指令 | 說明 |
|------|------|------|
| 絕對模式 | `@,ABS` | 移動到絕對位置 |
| 相對模式 | `@,REL` | 相對當前位置移動 |

#### 4.2.2 軸移動指令

**格式**: `@,<軸>,<距離>,<速度>,!`

**參數說明**:
- `<軸>`: X, Y, 或 Z
- `<距離>`: 整數，單位為 steps
  - 正數: 正向移動
  - 負數: 反向移動
- `<速度>`: 整數，單位為 μs/step (微秒/步)
  - 數值越小，速度越快
  - 建議範圍: 100-1000

**範例**:
```
@,X,1000,200,!  # X軸正向移動1000步，速度200μs/step
@,Y,-500,150,!  # Y軸反向移動500步，速度150μs/step
@,Z,2000,300,!  # Z軸正向移動2000步，速度300μs/step
```

### 4.3 狀態回報格式

| 類型 | 格式 | 範例 | 觸發時機 |
|------|------|------|----------|
| 初始化 | `Ready` | `Ready` | ESP32 啟動完成 |
| 模式變更 | `Mode:<模式>` | `Mode:ABS` | 切換模式後 |
| 位置更新 | `X:<值> Y:<值> Z:<值>` | `X:1234 Y:5678 Z:90` | 每 200ms |

---

## 5. 類別設計

### 5.1 ESP32BLEService

**檔案**: `lib/ble_service.dart`

**職責**:
- 管理 BLE 連接生命週期
- 封裝通訊協定
- 提供高階 API 給 UI 層

**屬性**:

```dart
class ESP32BLEService {
  // 連接物件
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? cmdCharacteristic;
  BluetoothCharacteristic? statCharacteristic;

  // 狀態串流
  StreamController<String> _statusStreamController;
  Stream<String> get statusStream;

  // 常數
  static const String serviceUUID;
  static const String cmdCharUUID;
  static const String statCharUUID;
  static const String targetDeviceName;
}
```

**方法**:

| 方法 | 參數 | 回傳 | 說明 |
|------|------|------|------|
| `scanForDevices()` | - | `Stream<List<ScanResult>>` | 開始掃描裝置 |
| `stopScan()` | - | `void` | 停止掃描 |
| `connect()` | `BluetoothDevice device` | `Future<bool>` | 連接到裝置 |
| `disconnect()` | - | `Future<void>` | 斷開連接 |
| `sendCommand()` | `String command` | `Future<void>` | 發送原始指令 |
| `setAbsoluteMode()` | - | `Future<void>` | 切換到絕對模式 |
| `setRelativeMode()` | - | `Future<void>` | 切換到相對模式 |
| `moveX()` | `int distance, int speed` | `Future<void>` | 移動 X 軸 |
| `moveY()` | `int distance, int speed` | `Future<void>` | 移動 Y 軸 |
| `moveZ()` | `int distance, int speed` | `Future<void>` | 移動 Z 軸 |
| `isConnected` | - | `bool` | 檢查連接狀態 |
| `dispose()` | - | `void` | 釋放資源 |

### 5.2 ScanPage

**檔案**: `lib/scan_page.dart`

**職責**:
- 請求藍芽權限
- 顯示裝置列表
- 處理裝置連接

**狀態變數**:

```dart
class _ScanPageState extends State<ScanPage> {
  final ESP32BLEService bleService;
  bool isScanning;           // 掃描中標誌
  bool isConnecting;         // 連接中標誌
}
```

**主要方法**:

| 方法 | 說明 |
|------|------|
| `_checkPermissions()` | 檢查並請求藍芽權限 |
| `_startScan()` | 開始掃描 |
| `_stopScan()` | 停止掃描 |
| `_connectToDevice()` | 連接到選中的裝置 |

### 5.3 ControlPage

**檔案**: `lib/control_page.dart`

**職責**:
- 顯示連接狀態和位置資訊
- 提供軸控制介面
- 處理模式切換

**狀態變數**:

```dart
class _ControlPageState extends State<ControlPage> {
  final ESP32BLEService bleService;
  String status;                  // 狀態訊息
  bool isAbsoluteMode;           // 模式標誌
  int xPos, yPos, zPos;          // 軸位置

  // 輸入控制器
  TextEditingController xDistController;
  TextEditingController yDistController;
  TextEditingController zDistController;
  TextEditingController speedController;
}
```

**主要方法**:

| 方法 | 說明 |
|------|------|
| `_parsePosition()` | 解析位置字串 |
| `_toggleMode()` | 切換模式 |
| `_moveAxis()` | 移動指定軸 |
| `_quickMoveButton()` | 建立快速移動按鈕 Widget |
| `_axisControlPanel()` | 建立軸控制面板 Widget |

---

## 6. 使用者介面設計

### 6.1 ScanPage 介面結構

```
┌────────────────────────────────┐
│  掃描 ESP32 設備          [⌂]  │
├────────────────────────────────┤
│ ┌────────────────────────────┐ │
│ │   [開始掃描 / 停止掃描]    │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ [🔵] ESP32_XYZ_Table       │ │
│ │      AA:BB:CC:DD:EE:FF     │ │
│ │      信號強度: -45 dBm     │ │
│ │                  [連接] →  │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ [⚪] Other Device          │ │
│ │      ...                   │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

### 6.2 ControlPage 介面結構

```
┌────────────────────────────────┐
│  ESP32 XYZ 控制台     [⚡] [X] │
├────────────────────────────────┤
│ ┌────────────────────────────┐ │
│ │   連接狀態                  │ │
│ │   X:1234 Y:5678 Z:90       │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ 移動模式   [相對模式 ⭘] ←→ │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ 移動速度   [____200____] μs │ │
│ └────────────────────────────┘ │
│                                │
│ ╔════════════════════════════╗ │
│ ║         X 軸               ║ │
│ ║   當前位置: 1234           ║ │
│ ║                            ║ │
│ ║ [_1000_] steps [移動] →    ║ │
│ ║                            ║ │
│ ║ [-1000] [-100] [+100] [+1000] ║
│ ╚════════════════════════════╝ │
│                                │
│ ╔════════════════════════════╗ │
│ ║         Y 軸               ║ │
│ ║   ...                      ║ │
│ ╚════════════════════════════╝ │
│                                │
│ ╔════════════════════════════╗ │
│ ║         Z 軸               ║ │
│ ║   ...                      ║ │
│ ╚════════════════════════════╝ │
└────────────────────────────────┘
```

### 6.3 色彩設計

| 元素 | 顏色 | 用途 |
|------|------|------|
| 主要色 | `Colors.blue` | 按鈕、AppBar |
| 強調色 | `Colors.blue.shade50` | 目標裝置、狀態卡片 |
| 成功色 | `Colors.green` | 正向移動按鈕 |
| 警告色 | `Colors.orange` | 負向移動按鈕 |
| 錯誤色 | `Colors.red` | 停止掃描按鈕 |
| 絕對模式 | `Colors.purple` | 模式文字 |
| 相對模式 | `Colors.green` | 模式文字 |

---

## 7. 錯誤處理設計

### 7.1 連接錯誤

| 錯誤情境 | 處理方式 |
|---------|---------|
| 藍芽未開啟 | 顯示提示訊息，引導使用者開啟藍芽 |
| 權限被拒絕 | 顯示權限說明，請求重新授權 |
| 連接逾時 | 顯示錯誤訊息，允許重試 |
| 找不到服務 | 斷開連接，提示檢查 ESP32 程式 |

### 7.2 通訊錯誤

| 錯誤情境 | 處理方式 |
|---------|---------|
| 寫入失敗 | 顯示錯誤訊息，允許重試 |
| 連接中斷 | 自動返回掃描頁面 |
| 指令格式錯誤 | 記錄錯誤，不發送指令 |

### 7.3 輸入驗證

| 檢查項目 | 驗證規則 |
|---------|---------|
| 移動距離 | 必須為整數 |
| 移動速度 | 必須為正整數，建議 100-1000 |
| 連接狀態 | 發送指令前檢查連接 |

---

## 8. 效能考量

### 8.1 資源管理

- **串流管理**: 使用 `StreamController.broadcast()` 允許多個監聽者
- **記憶體管理**: 在 `dispose()` 中釋放 TextEditingController 和 StreamController
- **連接管理**: 離開頁面時自動斷開連接

### 8.2 UI 流暢度

- **非同步操作**: 所有 BLE 操作使用 `async/await`
- **狀態更新**: 使用 `setState()` 最小範圍更新 UI
- **列表渲染**: 使用 `ListView.builder` 延遲載入

### 8.3 網路效能

- **掃描逾時**: 設定 10 秒掃描逾時
- **連接逾時**: 設定 10 秒連接逾時
- **通知頻率**: ESP32 每 200ms 發送一次位置更新

---

## 9. 安全性設計

### 9.1 權限管理

- 僅請求必要權限
- 在 AndroidManifest.xml 中使用 `neverForLocation` 標記
- iOS 提供詳細的權限說明文字

### 9.2 資料驗證

- 驗證所有使用者輸入
- 解析狀態字串時使用 try-catch
- 檢查連接狀態後才發送指令

### 9.3 連接安全

- 僅連接到指定裝置名稱
- 驗證 Service UUID 和 Characteristic UUID
- 連接失敗時不洩漏敏感資訊

---

## 10. 測試策略

### 10.1 單元測試

- BLE 服務類別方法測試
- 指令格式化測試
- 狀態解析測試

### 10.2 整合測試

- 掃描流程測試
- 連接流程測試
- 指令發送和接收測試

### 10.3 UI 測試

- 頁面導航測試
- 按鈕互動測試
- 輸入驗證測試

### 10.4 實機測試

- Android 實體裝置測試
- iOS 實體裝置測試 (如有)
- 不同藍芽環境測試

---

## 11. 部署計劃

### 11.1 Android 部署

**Debug 版本**:
```bash
flutter run
```

**Release APK**:
```bash
flutter build apk --release
```
輸出位置: `build/app/outputs/flutter-apk/app-release.apk`

### 11.2 iOS 部署

**Debug 版本**:
```bash
flutter run
```

**Release IPA**:
```bash
flutter build ios --release
```
需要 Apple Developer 帳號進行簽名。

---

## 12. 維護計劃

### 12.1 版本更新

- 根據使用者回饋新增功能
- 更新相依套件到最新版本
- 修復已知問題

### 12.2 文件維護

- 更新 README.md 使用說明
- 更新 STATUS.md 開發進度
- 更新本設計文件

### 12.3 程式碼維護

- 重構重複程式碼
- 優化效能瓶頸
- 改善錯誤處理

---

## 13. 未來擴展

### 13.1 功能擴展

- [ ] 新增預設位置功能
- [ ] 新增操作歷史記錄
- [ ] 新增軌跡規劃功能
- [ ] 新增多軸同步移動
- [ ] 新增 G-code 支援

### 13.2 UI/UX 改進

- [ ] 新增深色模式
- [ ] 新增手勢控制
- [ ] 新增視覺化顯示
- [ ] 新增操作教學

### 13.3 系統整合

- [ ] 新增雲端備份
- [ ] 新增裝置配對記憶
- [ ] 新增遠端監控
- [ ] 新增多裝置管理

---

## 附錄 A: 檔案清單

```
esp32_xyz_app/
├── lib/
│   ├── main.dart                    # 470 行，APP 入口
│   ├── ble_service.dart             # 1016 行，BLE 服務
│   ├── scan_page.dart               # 1598 行，掃描頁面
│   └── control_page.dart            # 2486 行，控制頁面
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # 575 行，Android 配置
├── ios/
│   └── Runner/
│       └── Info.plist               # 1168 行，iOS 配置
├── pubspec.yaml                     # 283 行，專案配置
├── README.md                        # 詳細說明文件
├── STATUS.md                        # 開發狀態文件
└── sdd.md                           # 本軟體設計文件
```

---

## 附錄 B: 技術決策記錄

### B.1 為何選擇 Flutter?

- **跨平台**: 一次開發，同時支援 Android 和 iOS
- **效能**: 原生編譯，效能接近原生 APP
- **社群**: 龐大的社群和豐富的套件生態
- **開發效率**: Hot Reload 提高開發速度

### B.2 為何選擇 flutter_blue_plus?

- **活躍維護**: 持續更新和維護
- **功能完整**: 支援所有必要的 BLE 功能
- **社群支援**: 大量的範例和問題解答
- **穩定性**: 經過大量專案驗證

### B.3 為何使用 BLE 而非經典藍芽?

- **功耗**: BLE 功耗更低
- **iOS 支援**: iOS 對 BLE 支援更好
- **現代化**: BLE 是新一代藍芽標準
- **簡單**: GATT 架構更容易理解和實作

---

## 結語

本文件詳細記錄了 ESP32 XYZ 控制台 APP 的軟體設計。隨著專案的進展和測試結果，本文件將持續更新以反映最新的設計決策和實作細節。
