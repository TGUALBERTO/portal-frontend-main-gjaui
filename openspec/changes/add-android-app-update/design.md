## Context

The pipeline (`build_apk` on `main`) produces a release APK signed with a fixed
keystore and publishes it in three places; the one that matters here is the production
web image, which serves:

```
https://portal.rebic.com.br/downloads/android/latest.json
https://portal.rebic.com.br/downloads/android/gjamobile-<versionName>.apk
```

```json
{ "versionCode": 119, "versionName": "2026.10.02.13.46",
  "apk": "gjamobile-2026.10.02.13.46.apk", "size": 108373219,
  "sha256": "<hex>", "signerSha256": "<hex>", "commit": "d242ba97",
  "builtAt": "2026-10-02T16:55:00Z" }
```

`versionCode` is `CI_PIPELINE_IID`: an integer that only grows. The app already reads
its own version through `AppVersionService` (`package_info_plus`), but only the name.

Constraints that shape the design:

- The project's GitLab is private. No token may be embedded in the binary, so the app
  cannot ask GitLab for releases. The static channel needs no credential.
- One APK serves every backend environment: QAS/PRD is a runtime choice in the app.
  Only `main` builds the APK, and it is published only on the production web host.
- The target device is a dock collector operated with gloves. Interruptions cost real
  work (re-reading a whole truck), so the feature must never get in the way.
- Android installs an update over an app only if both are signed with the same
  certificate. A sideloaded install always goes through a system confirmation; there is
  no silent install without device-owner/MDM.
- CLAUDE.md conventions: feature-first under `lib/src/features/<feature>/`, signals
  controllers with private signals and read-only getters, `auto_injector`, `runTask` in
  the data layer, shared widgets and design tokens in the UI.

## Goals / Non-Goals

**Goals:**

- Detect a newer build at app start, on Android release builds, with zero cost to
  startup time and zero noise when anything fails.
- Download, verify and hand over to the system installer with as few taps as Android
  allows.
- Keep the whole thing testable without a device: the decision logic lives in a
  controller with injected collaborators.
- No new plugin.

**Non-Goals:**

- Silent or forced installation (needs MDM/device owner).
- Mandatory updates / minimum supported version. `latest.json` has no such field yet;
  the controller is shaped so one can be added later.
- Delta/patch updates, resumable downloads, background downloads while the app is closed.
- Windows or web self-update (the web is always current; Windows is published by script).
- Release notes.
- Removing the unused store-based `VersionUpdateService`.

## Decisions

### D1. Static channel at a fixed production URL, outside `BackendService`

`AppUpdateConfig.channelBaseUrl` is a compile-time constant
(`https://portal.rebic.com.br/downloads/android`), overridable with
`--dart-define=APP_UPDATE_BASE_URL=...` for tests. It does not follow
`AppConfig.environment`.

- *Why not a `BackendService`*: that registry models authenticated APIs with one host
  per environment, built by `AppConfig` with the Microsoft auth interceptor. The channel
  is one static host, the same for every environment, and must not receive the bearer
  token. A dedicated plain `Dio` (no interceptors), wrapped in an `AppUpdateDio` marker
  type so `auto_injector` can tell it apart, keeps the existing convention of "one typed
  Dio per destination" without bending the registry.
- *Why not GitLab Releases*: private project → token in the binary.
- *Why not a backend endpoint*: needs backend work and auth; the check should also work
  before login.

### D2. Integer comparison on `versionCode`

`update available ⇔ latest.versionCode > installedBuildNumber`. `AppVersionService`
gains `buildNumber` (from `PackageInfo.buildNumber`). No string/semver parsing: the
version *name* is a timestamp for humans only.

### D3. Eligibility: platform, build mode and signer

The check runs only when `PlatformInfo.isAndroid && (kReleaseMode || forced)`, where
`forced` is `--dart-define=APP_UPDATE_FORCE=true` (used to exercise the flow on an
emulator with debug builds).

After a newer `versionCode` is found, the installed signing-certificate digest is
compared with `latest.signerSha256` (when present). On mismatch the update is not
offered. Every field install that contains this feature comes from the pipeline and
matches; the mismatch case is a developer's local release build, which Android would
reject with "App not installed" after a 100 MB download.

### D4. A method channel in `MainActivity`, not a plugin

Channel `com.gja.gjamobile/app_update`:

| Method | Returns | Native side |
| --- | --- | --- |
| `signerSha256` | lowercase hex | `PackageManager` signing info → SHA-256 |
| `installApk(path)` | — | `FileProvider.getUriForFile` + `ACTION_VIEW` with the APK MIME type and `FLAG_GRANT_READ_URI_PERMISSION` |

Manifest: `REQUEST_INSTALL_PACKAGES` and a `FileProvider` with authority
`${applicationId}.appupdate` exposing only `cache/app_update/`.

- *Alternatives*: `open_filex` or `ota_update`. Both add a plugin (the build already
  warns that plugins applying the Kotlin Gradle Plugin will break future Flutter
  versions), neither can read the signing certificate, and `ota_update` downloads on
  the native side, outside the app's `Dio` and its testable progress/verification.
  About forty lines of Kotlin cover exactly what is needed.
- *Unknown-sources permission*: not pre-checked. When the app lacks it, the system
  installer itself explains and links to the setting, then returns to the install
  prompt. Declaring `REQUEST_INSTALL_PACKAGES` is what makes that flow possible.

Dart sees the channel through an `AppUpdatePlatform` abstraction so the controller can
be tested with a fake.

### D5. Download to the app cache, verify, then install

- Destination: `<temporaryDirectory>/app_update/<apk>`. On Android that is the app's
  private `cacheDir`, the only place the `FileProvider` exposes.
- `Dio.download` with `onReceiveProgress` and a `CancelToken`; long `receiveTimeout`
  (the file is ~80–110 MB on dock Wi-Fi).
- Verification before install: file length equals `size`, then SHA-256 equals `sha256`,
  hashed from a file stream inside `Isolate.run` so the UI thread stays free.
- A file already in the cache that passes verification is reused (the user backed out
  of the installer, or the app was restarted after downloading).
- On verification failure the file is deleted and the dialog offers to retry.
- After every check, files in `app_update/` other than the published `apk` are deleted.

The signature is not verified in Dart: Android enforces it at install time, and D3
already prevents the doomed case.

### D6. Controller as a small state machine

`AppUpdateController` (app-scoped singleton) exposes read-only signals:

```
status:   idle → checking → upToDate
                          → available → downloading → verifying → readyToInstall
                                                                → (installer launched)
                          ↘ failed (download/verify error; retry goes back to downloading)
release:  AppRelease?      (non-null from `available` on)
progress: double (0..1)    (meaningful while downloading)
error:    AppFailure?
promptDismissed: bool      (user chose "later" in this run)
```

`isUpdateAvailable` is a `computed`: a release is known and the status is anything from
`available` onwards. A failed *check* returns to `idle`/`upToDate` silently (D8); only
download/verification failures surface as `failed`, inside the dialog the user opened.

Collaborators are constructor-injected: `AppUpdateRepository`, `AppUpdatePlatform` and
an `installedBuildNumber` reader, so tests need no platform channel.

### D7. UI: one listener, one dialog, one Home entry

- `AppUpdateListener` wraps the app in `MaterialApp.builder`, next to
  `SessionListenerWrapper`. After the first frame it calls
  `controller.checkForUpdate()`. An `effect` opens the dialog when an update is
  available, the prompt was not dismissed, and the session status is no longer
  `unknown` (so it never appears over the native splash). It also observes the app
  lifecycle: on resume, if the last check is older than six hours, it re-checks
  silently — availability refreshes, no dialog (collectors stay open for days, and a
  dialog in the middle of a count is exactly the interruption to avoid).
- `AppUpdateDialog` is driven by `SignalBuilder`: versions and size, a progress bar
  while downloading, error text with retry, and "Instalar" once the file is verified.
  It cannot be dismissed by tapping outside while a download is running; it has an
  explicit cancel.
- Home: an "Atualizar app" `HomeAppButton` in the existing "Sessão" group, visible only
  while `isUpdateAvailable`.

### D8. The check never speaks

`runTask(requiresNetwork: true)` raises a global "no internet" toast, which is right
for a user action and wrong for a background check. The repository uses plain
`runTask` and the controller swallows check failures after logging them.

### D9. ARM-only release APK

`flutter build apk --target-platform android-arm,android-arm64`. The published APK is
~108 MB with three ABIs; `x86_64` exists for emulators only. Developers keep building
for emulators locally, where the default still includes `x86_64`.

## Risks / Trade-offs

- **The native install path cannot be unit-tested** → verified end to end on an
  emulator with two debug builds (same debug key, different build numbers) served by a
  local HTTP server through `adb reverse`, with `APP_UPDATE_FORCE` and
  `APP_UPDATE_BASE_URL`.
- **Every push to `main` yields a new `versionCode`, so every collector is prompted
  after each release** → accepted: the app code is shared with the web, so each `main`
  build is a new app version. The prompt is once per app start and "later" is one tap.
- **Channel disappears when `build_apk` fails** (the web image is then built without
  `/downloads/android`) → the app sees a 404, which is a silent no-update (D8).
- **A user backs out of the system installer** → the verified file stays in the cache
  and the dialog still offers "Instalar".
- **Download of ~100 MB on a weak link** → cancel + retry, verification catches a
  truncated file; D9 shrinks the file.
- **Old installs signed with a debug key** → they do not contain this feature; they
  need the one-time manual reinstall already documented.
- **`x86_64` devices can no longer install the CI APK** → no such device is in use.

## Migration Plan

1. Ship on `qas`, then `main`. The first `main` build that contains the feature must be
   installed manually once (it replaces a build that cannot self-update).
2. From the following `main` build on, collectors pick the update up on app start.
3. Rollback: the feature is additive. Reverting the change removes the listener; the
   channel can stay published.

## Open Questions

- Should some builds be mandatory? Needs a `minVersionCode` (or similar) in
  `latest.json` and a blocking variant of the dialog. Out of scope here.
