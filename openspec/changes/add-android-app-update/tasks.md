## 1. Pipeline

- [x] 1.1 Build the release APK for ARM only: add `--target-platform android-arm,android-arm64` to `flutter build apk` in `build_apk` (`.gitlab-ci.yml`), with a comment on why

## 2. Android platform side

- [x] 2.1 Declare `REQUEST_INSTALL_PACKAGES` in `AndroidManifest.xml`
- [x] 2.2 Add `res/xml/app_update_paths.xml` exposing only `cache/app_update/` and register a `FileProvider` with authority `${applicationId}.appupdate`
- [x] 2.3 Implement the `com.gja.gjamobile/app_update` method channel in `MainActivity.kt` (`signerSha256`, `installApk`)

## 3. Domain and data

- [x] 3.1 Create `AppRelease` entity with strict `fromJson` (required fields, types) and `isNewerThan(installedBuildNumber)`
- [x] 3.2 Create `AppUpdateConfig` (channel base URL and force switch from `--dart-define`, re-check interval) and the `AppUpdateDio` marker type
- [x] 3.3 Expose `buildNumber` in `AppVersionService`
- [x] 3.4 Create `AppUpdatePlatform` (abstraction + method-channel implementation)
- [x] 3.5 Create `AppUpdateRepository`: `fetchLatest`, `download` (progress, cancel), `verify` (size + SHA-256 in an isolate), `cachedApk`, `cleanStale`

## 4. Controller

- [x] 4.1 Create `AppUpdateController` with the status/release/progress/error/promptDismissed signals and `isUpdateAvailable`
- [x] 4.2 Implement `checkForUpdate` (eligibility, version comparison, signer guard, silent failure, stale cleanup, re-check interval)
- [x] 4.3 Implement `startUpdate` / `cancelDownload` / `install` / `dismissPrompt` (reuse of a verified cached file, failure → retry)

## 5. Presentation

- [x] 5.1 Create `AppUpdateDialog` (versions, size, progress, error + retry, install) driven by `SignalBuilder`
- [x] 5.2 Create `AppUpdateListener` (first-frame check, effect that opens the dialog once per run after the session is known, silent re-check on resume)
- [x] 5.3 Add the "Atualizar app" entry to the Home "Sessão" group while an update is pending

## 6. Wiring

- [x] 6.1 Register `AppUpdateDio`, `AppUpdatePlatform`, `AppUpdateRepository` and `AppUpdateController` in `AppInjector`
- [x] 6.2 Add `AppUpdateListener` to the wrapper chain in `app.dart`

## 7. Tests

- [x] 7.1 `AppRelease`: parsing of a valid document, rejection of malformed ones, version comparison
- [x] 7.2 `AppUpdateRepository.verify`: matching file, wrong size, wrong hash
- [x] 7.3 `AppUpdateController`: up to date, update available, signer mismatch, silent check failure, download → verify → install, corrupted download, cancel, cached file reuse, dismiss
- [x] 7.4 `AppUpdateDialog` widget test: available, downloading and failed states

## 8. Verification

- [x] 8.1 `flutter analyze` clean and `flutter test` green
- [x] 8.2 Android build compiles with the new native code (`flutter build apk`)
- [ ] 8.3 End-to-end on the emulator: older debug build detects, downloads, verifies and launches the installer for a newer debug build served locally; installed `versionCode` changes after confirming

## 9. Documentation

- [x] 9.1 Update README ("APK Android") and CLAUDE.md with the in-app update flow, the dart-defines and how to test it
