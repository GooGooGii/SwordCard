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

## GitHub Actions 自動產 APK

2026-05-21 已確認 GitHub Actions 可以在 push 到 `main` 時自動產生 Android APK。

成功 commit:

- `2deea3d ci: build Android APK on push`

成功 workflow run:

- `Build Android APK`
- Run URL: `https://github.com/GooGooGii/SwordCard/actions/runs/26207930283`
- Event: `push`
- Branch: `main`
- Result: `success`
- Artifact: `SwordCard-debug-apk`

Artifact 內容：

- `SwordCard.apk`
- `export.log`

下載 artifact 後本機驗證結果：

- APK size: `61,134,400 bytes`
- `apksigner verify --verbose`: `Verifies`
- v2 signature: `true`
- v3 signature: `true`
- Number of signers: `1`

### CI 成功要點

Actions workflow 使用 `.github/workflows/build-android.yml`，關鍵條件如下。

1. 每次 push 到 `main` 觸發：

```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:
```

2. 使用 `barichello/godot-ci:4.6` container，搭配 repo 內的 Godot 4.6 Android preset。

3. Android SDK 需明確補齊以下套件：

```text
platform-tools
platforms;android-35
build-tools;35.0.1
cmake;3.10.2.4988404
ndk;28.1.13356709
```

只裝 `platform-tools`、`platforms`、`build-tools` 不夠。Godot 4.6 Android export validation 也會檢查 NDK/CMake，缺少時可能只顯示：

```text
Cannot export project with preset "Android" due to configuration errors:
```

4. CI 直接寫入 Android SDK license hash 到 `$ANDROID_SDK/licenses`，避免 `sdkmanager --licenses` 在非互動環境卡住。

5. CI 產生 debug keystore：

```text
$HOME/debug.keystore
alias: androiddebugkey
storepass/keypass: android
```

並同時設定：

```text
GODOT_ANDROID_KEYSTORE_DEBUG_PATH
GODOT_ANDROID_KEYSTORE_DEBUG_USER
GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
```

6. 走本機已驗證成功的非 Gradle legacy APK build：

```ini
gradle_build/use_gradle_build=false
gradle_build/min_sdk=""
gradle_build/target_sdk=""
architectures/arm64-v8a=true
package/signed=true
```

非 Gradle build 不要填 `min_sdk` / `target_sdk`。這兩個欄位只有 Gradle build 可覆寫。

7. Launcher icons 必須使用已提交的 PNG 檔：

```ini
launcher_icons/main_192x192="res://icon_192.png"
launcher_icons/adaptive_foreground_432x432="res://icon_foreground_432.png"
launcher_icons/adaptive_background_432x432="res://icon_background_432.png"
```

8. `project.godot` 必須包含 Android texture import 設定：

```ini
textures/vram_compression/import_etc2_astc=true
```

9. 匯出後要在 CI 內立即驗證 APK：

```bash
apksigner verify --verbose build/android/SwordCard.apk
```

10. 上傳 artifact 時同時保留 APK 與 export log：

```yaml
path: |
  build/android/SwordCard.apk
  build/android/export.log
```

### 目前 CI 已知提醒

GitHub Actions 目前會顯示 Node.js 20 deprecation warning，來源是 `actions/checkout@v4` 與 `actions/upload-artifact@v4`。這不是 APK build failure，且 2026-05-21 的 run 已成功產出 APK。
