# ESP32 XYZ 控制台 APP

**最後更新時間**: 2025-10-23 (重新開機前)

**當前狀態**: ✅ APP 開發完成 + Flutter 環境已配置 (95%)

**下一步計劃**:
1. ✅ ~~安裝 Flutter SDK~~ (已完成，v3.35.6)
2. ✅ ~~執行 `flutter pub get` 安裝相依套件~~ (已完成)
3. ⏳ 重新開機並啟用 Windows 開發者模式
4. 執行 `flutter run -d windows` 測試 UI
5. **重要**: 未來需要 Android 手機才能測試真實藍芽功能

**快速恢復**: 重新開機後請先查看 [RESUME.md](RESUME.md) 快速恢復指南

---

## 專案簡介

這是一個跨平台的 Flutter APP，用於透過藍芽 BLE 連接和控制 ESP32 XYZ 三軸控制台。

## 功能特色

- ✅ 藍芽 BLE 裝置掃描
- ✅ 自動識別 ESP32_XYZ_Table 裝置
- ✅ 即時連接狀態顯示
- ✅ XYZ 三軸獨立控制
- ✅ 絕對/相對移動模式切換
- ✅ 自訂移動距離和速度
- ✅ 快速移動按鈕 (±100, ±1000 steps)
- ✅ 即時位置顯示

## 技術架構

### 前端 (Flutter)
- **語言**: Dart
- **框架**: Flutter 3.x
- **主要套件**:
  - `flutter_blue_plus`: 藍芽 BLE 通訊
  - `permission_handler`: 權限管理

### 後端 (ESP32)
- **晶片**: ESP32
- **藍芽**: BLE (Bluetooth Low Energy)
- **裝置名稱**: ESP32_XYZ_Table
- **Service UUID**: `12345678-1234-5678-1234-56789abcdef0`

## ESP32 通訊協定

### BLE 特徵值

| 類型 | UUID | 功能 |
|------|------|------|
| Command (寫入) | `12345678-1234-5678-1234-56789abcdef1` | 發送控制指令 |
| Status (通知) | `12345678-1234-5678-1234-56789abcdef2` | 接收狀態更新 |

### 指令格式

```
模式切換:
@,ABS          # 切換到絕對模式
@,REL          # 切換到相對模式

軸移動:
@,X,1000,200,! # 格式: @,軸名,距離,速度,!
@,Y,-500,150,! # 負數表示反向移動
@,Z,2000,300,!
```

### 狀態回報格式

```
Ready              # 初始化完成
Mode:ABS          # 模式變更通知
Mode:REL
X:1234 Y:5678 Z:90 # 位置更新 (每 200ms)
```

## 專案結構

```
esp32_xyz_app/
├── lib/
│   ├── main.dart           # APP 入口
│   ├── ble_service.dart    # BLE 通訊服務
│   ├── scan_page.dart      # 裝置掃描頁面
│   └── control_page.dart   # 控制台頁面
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml  # Android 權限設定
├── ios/
│   └── Runner/
│       └── Info.plist      # iOS 權限設定
├── pubspec.yaml            # 專案設定檔
├── README.md               # 本文件
├── STATUS.md               # 開發狀態追蹤
└── sdd.md                  # 軟體設計文件
```

## 安裝步驟

### 1. 安裝 Flutter SDK

前往 [Flutter 官網](https://flutter.dev/) 下載並安裝 Flutter SDK。

### 2. 安裝相依套件

```bash
cd C:\D槽\esp32_xyz_app
flutter pub get
```

### 3. 執行在 Android 裝置

```bash
flutter run
```

或建置 APK:

```bash
flutter build apk --release
```

APK 檔案位置: `build/app/outputs/flutter-apk/app-release.apk`

### 4. 執行在 iOS 裝置

需要 Mac 電腦和 Xcode:

```bash
flutter run
```

或建置 IPA:

```bash
flutter build ios --release
```

## 使用說明

### 1. 開啟 ESP32
確保 ESP32 已燒錄程式並通電，藍芽廣播名稱為 `ESP32_XYZ_Table`。

### 2. 啟動 APP
開啟 APP 後會自動進入掃描頁面。

### 3. 掃描裝置
點擊「開始掃描」按鈕，APP 會列出附近的藍芽裝置。

### 4. 連接 ESP32
找到 `ESP32_XYZ_Table` 裝置（會以藍色標示），點擊「連接」。

### 5. 控制 XYZ 軸
連接成功後進入控制頁面，可以:
- 切換絕對/相對模式
- 設定移動速度
- 輸入距離並移動各軸
- 使用快速移動按鈕
- 查看即時位置

## 權限說明

### Android
- 藍芽掃描 (BLUETOOTH_SCAN)
- 藍芽連接 (BLUETOOTH_CONNECT)
- 位置權限 (LOCATION) - Android 要求用於藍芽掃描

### iOS
- 藍芽使用權限 (NSBluetoothAlwaysUsageDescription)

## 疑難排解

### 1. 找不到 ESP32 裝置
- 確認 ESP32 已通電
- 確認藍芽已開啟
- 檢查 APP 是否有藍芽權限
- 重新掃描

### 2. 連接失敗
- 確認 ESP32 沒有被其他裝置連接
- 重啟 ESP32
- 重啟 APP

### 3. 指令沒有反應
- 檢查藍芽連接狀態
- 查看 ESP32 的序列埠輸出
- 確認指令格式正確

## 開發環境

- Flutter SDK: 3.0+
- Dart: 3.0+
- Android Studio / VS Code
- Android 裝置 (API 21+) 或 iOS 裝置 (iOS 12+)

## 授權

本專案為個人開發專案。

## 聯絡資訊

如有問題，請查閱 STATUS.md 了解最新開發進度。
