---
description: Build, install, and launch the app on the Android emulator with Supabase config
argument-hint: "[device-id, default emulator-5554]"
allowed-tools: Bash, PowerShell, Read
---

Build, install, and launch this Flutter app on the Android emulator. Target device:
`$ARGUMENTS` (default `emulator-5554`). Follow these steps; this project has a few
environment quirks baked in below.

1. **Ensure config exists.** If `dart_defines.json` is missing, copy `dart_defines.example.json`
   to it and stop, telling the user to fill in their Supabase URL + anon key. The app can also
   run with no defines (offline/no-backend) — only do that if the user asks.

2. **Ensure the emulator is up.** Check `adb devices`. If no `emulator-####  device`, boot the
   AVD: `emulator -avd pixel_api35 -no-snapshot -gpu swiftshader_indirect -no-boot-anim`
   (detached), then poll `adb -s <device> shell getprop sys.boot_completed` until it returns `1`.

3. **Build the debug APK** (secrets come from the file, never the command line):
   ```
   flutter build apk --debug --dart-define-from-file=dart_defines.json
   ```

4. **Install + launch via adb** (NOT `flutter run` — its Dart VM Service / DDS attach is flaky
   on this emulator). Then launch the activity:
   ```
   adb -s <device> install -r build/app/outputs/flutter-apk/app-debug.apk
   adb -s <device> shell am force-stop com.example.kidslang.kids_lang
   adb -s <device> shell monkey -p com.example.kidslang.kids_lang -c android.intent.category.LAUNCHER 1
   ```

5. **Wait, then verify.** On a fresh emulator boot the network is slow, so `main()` can sit on
   the Flutter splash for ~10–15s while it initializes Supabase and signs in anonymously. Wait,
   then take a screenshot to confirm the home screen rendered:
   ```
   adb -s <device> shell screencap -p /sdcard/s.png
   adb -s <device> pull /sdcard/s.png <scratch>/home.png
   ```
   (Binary-safe pull — do NOT redirect `screencap` through PowerShell `>`, it corrupts the PNG.)

6. **Report** the result and, if anything failed, check `adb logcat` for `flutter`/`Exception`
   lines and the Supabase init message.
