// Android debug APK（QA-001a）：用 Android Studio 內附的 JDK 與本機 Android SDK 跑 Gradle。
// npm run android:build → android/app/build/outputs/apk/debug/app-debug.apk
import { spawnSync } from "node:child_process";
import { existsSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const home = process.env.LOCALAPPDATA ?? "";
const sdk = process.env.ANDROID_HOME ?? join(home, "Android", "Sdk");
const jdk = process.env.JAVA_HOME ?? "C:/Program Files/Android/Android Studio/jbr";
if (!existsSync(sdk)) throw new Error(`找不到 Android SDK：${sdk}`);
if (!existsSync(jdk)) throw new Error(`找不到 JDK：${jdk}（設定 JAVA_HOME）`);
writeFileSync("android/local.properties", `sdk.dir=${sdk.replaceAll("\\", "/")}\n`);
// 先刪掉舊 APK：debug 的增量打包會把換掉的素材留在檔案裡當廢空間（實測 43 MB 的內容變成 92 MB 的 APK）
rmSync(join("android", "app", "build", "outputs", "apk", "debug", "app-debug.apk"), { force: true });
// 用絕對路徑：Windows 的 cmd 不一定會在 cwd 找 gradlew.bat
const gradlew = join(process.cwd(), "android", process.platform === "win32" ? "gradlew.bat" : "gradlew");
const r = spawnSync(gradlew, ["assembleDebug"], {
  cwd: "android",
  stdio: "inherit",
  shell: true,
  env: { ...process.env, JAVA_HOME: jdk, ANDROID_HOME: sdk },
});
if (r.status !== 0) process.exit(r.status ?? 1);
console.log("APK：android/app/build/outputs/apk/debug/app-debug.apk");
