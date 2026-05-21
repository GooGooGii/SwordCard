# Android APK 本地匯出紀錄

本文記錄 2026-05-21 在 Windows 本機成功用 Godot 4.6.2 匯出 Android debug APK 的要點。

## 成功產物

- APK: `build/android/SwordCard-local.apk`
- Size: `61,138,496 bytes`
- SHA256: `650F730F9DAB010BD9059D84A5906C35BDA89F2B48008AF7B13757D490C5F029`
- Godot: `4.6.2.stable.official.71f334935`
- Android ABI: `arm64-v8a`
- 簽章: debug keystore, `androiddebugkey`

驗證結果：

```powershell
apksigner.bat verify --verbose build/android/SwordCard-local.apk
```

重點輸出：

```text
Verifies
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
```

## 本機工具鏈

本次成功使用的工具與路徑：

- Godot console: `C:\Users\sean.wu\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`
- JDK 17: `C:\Users\sean.wu\Tools\SwordCardBuild\jdk17\jdk-17.0.19+10`
- Android SDK: `C:\Users\sean.wu\AppData\Local\Android\Sdk`
- Debug keystore: `C:\Users\sean.wu\AppData\Roaming\Godot\keystores\debug.keystore`

Android SDK 需要安裝的套件：

```powershell
sdkmanager.bat --sdk_root="$env:LOCALAPPDATA\Android\Sdk" `
  "platform-tools" `
  "platforms;android-35" `
  "build-tools;35.0.1" `
  "cmake;3.10.2.4988404" `
  "ndk;28.1.13356709"
```

Godot 4.6 Android export 需要 CMake 與 NDK；只裝 platform/build-tools 仍會出現：

```text
Cannot export project with preset "Android" due to configuration errors:
```

## 專案設定要點

Android preset 使用非 Gradle legacy APK build：

- `gradle_build/use_gradle_build=false`
- `architectures/arm64-v8a=true`
- `package/unique_name="com.local.swordcard"`
- `package/signed=true`

非 Gradle build 時不要填 `gradle_build/min_sdk` 與 `gradle_build/target_sdk`，否則 Godot 會回報：

```text
只有在啟用「使用 Gradle 建置」時，才能覆寫「最低 SDK 版本」。
只有在啟用「使用 Gradle 建置」時，才能覆寫「Target SDK」。
```

Android launcher icons 改用 PNG，避免 Android export 對 SVG icon 的相容性問題：

- `icon_192.png`
- `icon_foreground_432.png`
- `icon_background_432.png`

`project.godot` 必須啟用 Android 需要的 ETC2/ASTC 匯入設定：

```ini
[rendering]

renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

少了這項時，Godot 4.6 headless export 可能只顯示空泛的 configuration errors。

## 匯出指令

```powershell
$godot="$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
$sdk="$env:LOCALAPPDATA\Android\Sdk"
$jdk="$env:USERPROFILE\Tools\SwordCardBuild\jdk17\jdk-17.0.19+10"

$env:JAVA_HOME=$jdk
$env:ANDROID_HOME=$sdk
$env:ANDROID_SDK_ROOT=$sdk
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$env:APPDATA\Godot\keystores\debug.keystore"
$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"
$env:PATH="$jdk\bin;$sdk\platform-tools;$sdk\cmdline-tools\latest\bin;$sdk\build-tools\35.0.1;$sdk\cmake\3.10.2.4988404\bin;$env:PATH"

New-Item -ItemType Directory -Force "build\android" | Out-Null
& $godot --headless --verbose --export-debug "Android" "build/android/SwordCard-local.apk"
```

成功時會看到：

```text
Starting legacy build system...
正在對齊 APK…
正在簽署除錯 APK…
Successfully completed signing build.
[ DONE ] export
```

## 驗證指令

```powershell
$apk="build/android/SwordCard-local.apk"
$sdk="$env:LOCALAPPDATA\Android\Sdk"
$jdk="$env:USERPROFILE\Tools\SwordCardBuild\jdk17\jdk-17.0.19+10"

$env:JAVA_HOME=$jdk
$env:PATH="$jdk\bin;$sdk\build-tools\35.0.1;$env:PATH"

Get-Item $apk
Get-FileHash $apk -Algorithm SHA256
& "$sdk\build-tools\35.0.1\apksigner.bat" verify --verbose $apk
```
