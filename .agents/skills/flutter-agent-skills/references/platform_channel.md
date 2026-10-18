# Plugin Platform Channel Reference

Companion to `AGENTS.md`. Template and rules for Flutter plugins that bridge to
**native code on every supported platform**: Android, iOS, Linux, macOS, Windows,
plus the browser (Web) and OpenHarmony (鸿蒙 / OHOS). The layered pattern is the
same everywhere — only the transport and native side differ.

## Layered pattern (keep this for every plugin)
1. **Platform interface** (`lib/<pkg>_platform_interface.dart`)
   - Abstract class `<Pkg>Platform extends PlatformInterface`.
   - Declares the public async API (`Future<T> doThing(...)`).
   - Provides an `instance` setter so the default impl can register itself.
2. **Concrete impl per platform** (`lib/<pkg>_method_channel.dart`, `<pkg>_web.dart`,
   `<pkg>_linux.dart`, `<pkg>_macos.dart`, `<pkg>_windows.dart`, `<pkg>_ohos.dart`, ...)
   - Each subclass extends `<Pkg>Platform` and implements the abstract API.
   - The barrel picks the right impl at runtime (see registration below).
3. **Barrel** (`lib/<pkg>.dart`)
   - Exports the public API + the platform interface; sets the default instance.
   - Never export `lib/src/` or the per-platform classes directly.

This keeps consumers calling the **abstract API only**; adding a platform never
changes consumer code.

## Registration (conditional on the running platform)
Use `dart:io` `Platform` (or `kIsWeb` from `foundation` for the browser) to pick
the implementation:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

void _registerDefaultImplementation() {
  if (kIsWeb) {
    <Pkg>Platform.instance = <Pkg>Web();
  } else if (Platform.isAndroid) {
    <Pkg>Platform.instance = <Pkg>MethodChannelPlatform();
  } else if (Platform.isIOS) {
    <Pkg>Platform.instance = <Pkg>MethodChannelPlatform();
  } else if (Platform.isLinux) {
    <Pkg>Platform.instance = <Pkg>Linux();
  } else if (Platform.isMacOS) {
    <Pkg>Platform.instance = <Pkg>Macos();
  } else if (Platform.isWindows) {
    <Pkg>Platform.instance = <Pkg>Windows();
  } else if (Platform.isOhos) {            // from `flutter_ohos` / OHOS embedding
    <Pkg>Platform.instance = <Pkg>Ohos();
  }
}
```

> `Platform.isOhos` is not part of the Dart SDK; on OpenHarmony use the
> `flutter_ohos` embedding (or detect via `Platform.operatingSystem`). The example
> above is illustrative — follow the current OHOS Flutter community API.

## Transport and native side per platform

| Platform | Transport | Native host code |
|----------|-----------|------------------|
| Android | `MethodChannel` (binary messaging) | `android/src/main/kotlin/com/example/pkg/<Pkg>Plugin.kt`; register in `onAttachedToEngine` / `registerWith`. |
| iOS | `MethodChannel` (binary messaging) | `ios/Classes/<Pkg>Plugin.swift`; register in `registerWithRegistrar`. |
| macOS | `MethodChannel` (binary messaging) | `macos/Classes/<Pkg>Plugin.swift`; same registrar pattern as iOS. |
| Linux | `MethodChannel` (binary messaging, DBus-free) | `linux/<pkg>_plugin.cc` (C++); register in the plugin registrant. |
| Windows | `MethodChannel` (binary messaging) | `windows/<pkg>_plugin.cpp` (C++); register in the plugin registrant. |
| Web | `package:js` / `dart:js_interop` (no MethodChannel) | Pure Dart talking to browser APIs / JS via `@JS` interop; `index.html` may load a JS lib. |
| OpenHarmony (鸿蒙) | `MethodChannel` via the OHOS embedding | `ohos/.../<Pkg>Plugin.ets` (ArkTS) using the Flutter OHOS plugin API. |

### Common rules for every transport
- Pass plain serializable args (Map / List / primitives); encode complex objects yourself.
- Handle `PlatformException` on the Dart side; surface a typed error, don't leak native traces.
- Native must reply on the same channel; use `result.success(...)` / `result.error(...)`.
- Keep native changes minimal; they exist only to fulfill the contract.

### Web-specific notes
Web has **no** `MethodChannel` to a native layer. Implement the same abstract API
in pure Dart using `dart:js_interop` (or the older `dart:js` / `package:js`) to call
browser APIs or a `<script>`-loaded JS library. Provide graceful degradation when a
browser API is unavailable.

### OpenHarmony (鸿蒙) notes
OHOS support is community-driven (`flutter_ohos` embedding, not yet in the official
stable SDK). The plugin pattern mirrors Android/iOS: an ArkTS plugin receives method
calls through the OHOS Flutter engine's channel and replies on the same channel.
Treat OHOS as an *opt-in* platform until it reaches official stable support, and gate
it behind a clear `isOhos` check so other platforms are unaffected.

## Method channel contract (Android / iOS / macOS / Linux / Windows / OHOS)
- One `MethodChannel('<com.example.pkg>/methods')` per plugin; method names are strings.
- Native must reply on the same channel; use `result.success(...)` / `result.error(...)`.

## Cross-platform checklist
- [ ] Declare the API once in the platform interface.
- [ ] Implement an impl for each target platform (stub + `throw UnsupportedError` is fine where a platform genuinely can't support a call).
- [ ] Register conditionally so the right impl loads at runtime.
- [ ] Add `platforms:` entries and the right `pluginClass`/`dartPluginClass` in `pubspec.yaml`.
- [ ] Document unsupported platforms in the package README.

## Release notes
- Bump `version` in `pubspec.yaml`; update `CHANGELOG.md`.
- `flutter pub publish --dry-run` before publishing; `k-paxian/dart-package-publisher` is one CI option.
- Do not pass OIDC fields to that publisher action; it uses access/refresh tokens only.
- For multi-platform plugins, verify the example builds on each target you claim support for.
