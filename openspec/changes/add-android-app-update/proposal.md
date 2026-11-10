## Why

The Android APK used by the dock collectors is distributed outside any app store.
The pipeline already builds it on `main`, signs it with a fixed release keystore and
publishes it, together with a `latest.json`, at
`https://portal.rebic.com.br/downloads/android/`. But nothing in the app reads that
channel: every update still means someone walking to each collector, downloading and
installing by hand. The channel is live and verified, so the missing half — the app
noticing a new build and installing it — can now be built on top of it.

## What Changes

- New `app_update` feature: on Android release builds, the app reads `latest.json`
  from the production update channel, compares its `versionCode` with the installed
  build number and, when a newer build exists, offers to update.
- The update flow downloads the APK with progress, verifies size and SHA-256 against
  `latest.json`, and hands the file to the system package installer.
- The prompt appears once per app start; "later" dismisses it for that run. While an
  update is pending, the Home "Sessão" group shows an "Atualizar app" entry.
- A build whose signing certificate differs from the published one (a developer's
  local build) is never offered the update — Android would refuse to install it.
- A small Android platform channel (no new plugin) exposes two things Dart cannot do
  alone: read the installed signing certificate and launch the installer through a
  `FileProvider`. The manifest gains `REQUEST_INSTALL_PACKAGES`.
- The CI release APK is built for ARM devices only (`android-arm`, `android-arm64`),
  dropping `x86_64`, which only serves emulators and inflates every download.
- The check is silent by design: an unreachable channel, a malformed `latest.json` or
  any other failure never interrupts the operator.

## Capabilities

### New Capabilities
- `android-app-update`: how the Android app discovers, downloads, verifies and
  installs a newer build of itself from the static update channel published by the
  pipeline, including when the check runs, when the user is prompted, the integrity
  checks before installation, and the contract of the published `latest.json`.

### Modified Capabilities
<!-- None. Existing specs cover RBAC and backend connectivity; the update channel is a
     static host, not a `BackendService`, so `backend-connectivity` is unchanged. -->

## Impact

- **New code**: `lib/src/features/app_update/` (domain entity, repository, platform
  bridge, controller, dialog and listener widgets).
- **Touched code**: `lib/src/app.dart` (listener wrapper), `lib/src/di/app_injector.dart`
  (registrations), `lib/src/services/app_version_service.dart` (expose build number),
  `lib/src/features/home/presentation/screens/home_page.dart` (pending-update entry).
- **Android**: `AndroidManifest.xml` (`REQUEST_INSTALL_PACKAGES`, `FileProvider`),
  `res/xml/app_update_paths.xml`, `MainActivity.kt` (method channel).
- **CI**: `.gitlab-ci.yml` `build_apk` gains `--target-platform android-arm,android-arm64`.
- **Dependencies**: none added. Uses `dio`, `crypto`, `path_provider` and
  `package_info_plus`, all already in `pubspec.yaml`.
- **Platforms**: Android only. Web and Windows are untouched (the feature is inert there).
- **Not affected**: backends, auth, RBAC. The channel is unauthenticated static content.
- **Leftover**: `VersionUpdateService` (store-based, `app_version_update` package) stays
  unused; removing it and the dependency is out of scope.
