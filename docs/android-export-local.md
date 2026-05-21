# Android 本機匯出指南

GitHub Actions CI 嘗試了 13 種組合（不同 Godot 版本、不同 container、不同 keystore 格式、Gradle / 非 Gradle）仍卡在 Godot 4.x 的一個**不印訊息的內部 silent validation**。Linux container 內似乎有特定環境條件無法滿足。

本機 Windows / macOS 桌面端**通常能正常匯出 Android APK**。以下是步驟。

---

## 1. 安裝 Godot 4.6

下載與你開發中相同版本：[godotengine.org/download](https://godotengine.org/download)

選 **Standard edition**（不需要 .NET 版）。

## 2. 安裝 JDK 17

[Eclipse Temurin JDK 17](https://adoptium.net/temurin/releases/?version=17) — Windows 選 .msi installer，會自動設 `JAVA_HOME`。

安裝完打開 PowerShell 確認：
```powershell
java -version
# 顯示 openjdk version "17.0.x"
```

## 3. 安裝 Android Command Line Tools

1. 到 [developer.android.com/studio](https://developer.android.com/studio) 拉到底「**Command line tools only**」
2. 解壓到 `C:\Android\cmdline-tools\latest\`（路徑結構要正確：cmdline-tools 底下要叫 `latest` 資料夾）
3. 加環境變數：
   ```
   ANDROID_HOME = C:\Android
   PATH += C:\Android\cmdline-tools\latest\bin
   ```
4. PowerShell 跑：
   ```powershell
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   ```
5. 同意條款：
   ```powershell
   sdkmanager --licenses
   # 全部按 y
   ```

## 4. 產生 Debug Keystore

PowerShell：
```powershell
cd $env:USERPROFILE
keytool -genkey -v `
  -keystore debug.keystore `
  -storetype JKS `
  -alias androiddebugkey `
  -storepass android -keypass android `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -dname "CN=Android Debug,O=Android,C=US"
```
產生 `C:\Users\<你>\debug.keystore`。

## 5. Godot 編輯器設定

打開 Godot → **Editor → Editor Settings** → 搜尋「android」：

| 欄位 | 值 |
|------|------|
| Android Sdk Path | `C:\Android` |
| Java Sdk Path | `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot` |
| Debug Keystore | `C:\Users\<你>\debug.keystore` |
| Debug Keystore User | `androiddebugkey` |
| Debug Keystore Pass | `android` |

## 6. 安裝 Android Build Template

打開專案 → **Project → Install Android Build Template** → 確認。會在專案根目錄產生 `android/` 資料夾。

## 7. 匯出設定

**Project → Export** → 選 **Android** preset：

- 勾選 **Use Gradle Build**
- Architectures：只勾 arm64-v8a
- Gradle Build → Min Sdk = **24**
- Gradle Build → Target Sdk = **34**
- Launcher Icons（可選）：如果用 SVG 會匯出失敗，請先用編輯器把 `icon.svg` 轉成 `icon_192.png` (192×192) 並指定為 main_192x192

點 **Export Project** → 輸出 `SwordCard.apk`。

## 8. 安裝到手機

**USB 線**：
```powershell
adb install SwordCard.apk
```

**手動**：把 apk 傳到手機 → 設定允許「未知來源安裝」→ 點 apk 安裝。

---

## CI 已知問題

CI 環境下 Godot 印「Cannot export project with preset "Android" due to configuration errors:」**訊息體為空**。已嘗試：

- Godot 4.3 / 4.4 / 4.6 / 4.6.3
- 自己下載 Godot vs `barichello/godot-ci` Docker image vs `firebelley/godot-export` action
- `use_gradle_build` true 與 false
- Min SDK 21 / 24 / 26
- Target SDK 33 / 34
- 自製 keystore vs 容器內預設 keystore (JKS 格式)
- 寫 editor_settings 到 `editor_settings-4.tres`、`editor_settings-4.4.tres`、`editor_settings-4.6.tres`
- 手動安裝 Android build template 到 `android/build/` + `.build_version` 4.x.stable
- PNG 取代 SVG launcher icons
- `package/signed=true/false`
- Pre-import + ADB start-server

均無法繞過。可能的根因（未證實）：
- Godot 4.x CLI export validation 的某個 check 不會把錯誤訊息加進 `err` string
- 與 `headless` 模式 + Linux Container 環境的某個 native call 有關
- Linux Container 缺少某個 X server / display 依賴

需在本機（有圖形界面）匯出。
