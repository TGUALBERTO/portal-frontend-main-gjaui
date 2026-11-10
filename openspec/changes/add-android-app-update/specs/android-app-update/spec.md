## ADDED Requirements

### Requirement: Update channel contract

The update channel SHALL be a static location that serves a `latest.json` document and,
next to it, the APK it describes. `latest.json` SHALL contain at least `versionCode`
(integer), `versionName` (string), `apk` (file name, relative to the channel), `size`
(bytes, integer) and `sha256` (lowercase hex of the APK). It MAY contain `signerSha256`
(lowercase hex of the signing certificate), `commit` and `builtAt`. The channel base URL
SHALL be fixed at build time and SHALL NOT depend on the backend environment selected in
the app.

#### Scenario: Channel describes the published APK
- **WHEN** the app requests `<channel>/latest.json`
- **THEN** it receives a document with `versionCode`, `versionName`, `apk`, `size` and `sha256`
- **AND** `<channel>/<apk>` serves a file whose size and SHA-256 match the document

#### Scenario: Channel is independent of the backend environment
- **WHEN** the operator switches the backend environment between QAS and PRD
- **THEN** the update check keeps reading the same channel URL

#### Scenario: Malformed document is rejected
- **WHEN** `latest.json` is missing a required field or has a field of the wrong type
- **THEN** the app treats the check as failed and offers no update

### Requirement: Update check runs only where it can install

The app SHALL check for updates only on Android release builds. On web, on desktop and
on debug builds the feature SHALL be inert: no request to the channel and no UI. A
build-time switch MAY force the feature on for testing.

#### Scenario: Release build on Android checks at startup
- **WHEN** an Android release build starts
- **THEN** the app requests `latest.json` once, after the first frame, without blocking startup

#### Scenario: Other platforms never check
- **WHEN** the app runs on web or Windows
- **THEN** no request is made to the update channel
- **AND** no update UI is shown

#### Scenario: Debug build never checks
- **WHEN** an Android debug build starts without the testing switch
- **THEN** no request is made to the update channel

### Requirement: Newer build detection

The app SHALL consider an update available only when `latest.json`'s `versionCode` is
strictly greater than the installed build number. Equal or lower values SHALL mean the
app is up to date.

#### Scenario: Higher versionCode is an update
- **WHEN** the installed build number is 119 and `latest.json` reports `versionCode` 120
- **THEN** an update is available

#### Scenario: Same versionCode is not an update
- **WHEN** the installed build number equals the published `versionCode`
- **THEN** no update is offered

#### Scenario: Lower versionCode is not an update
- **WHEN** the published `versionCode` is lower than the installed build number
- **THEN** no update is offered

### Requirement: Signing certificate must match

When `latest.json` carries `signerSha256`, the app SHALL offer the update only if the
installed app is signed with that same certificate. A mismatch SHALL suppress the
update without notifying the user, because Android would refuse the installation.

#### Scenario: Same certificate is offered the update
- **WHEN** the installed certificate digest equals `signerSha256`
- **THEN** the update is offered

#### Scenario: Different certificate is not offered the update
- **WHEN** the installed certificate digest differs from `signerSha256`
- **THEN** no update is offered
- **AND** the mismatch is logged

#### Scenario: Channel without signer information
- **WHEN** `latest.json` has no `signerSha256`
- **THEN** the certificate check is skipped and the update is offered

### Requirement: User is prompted once per app start

When an update is available the app SHALL show a dialog naming the installed and the
new version and the download size, with an action to update and an action to postpone.
The dialog SHALL be shown at most once per app start and only after the session state is
known. Postponing SHALL keep the app fully usable.

#### Scenario: Prompt on startup
- **WHEN** the startup check finds an update
- **THEN** the update dialog is shown over the current screen

#### Scenario: Postponed prompt does not come back in the same run
- **WHEN** the user chooses to update later
- **THEN** the dialog closes
- **AND** it is not shown again until the app is restarted

#### Scenario: Re-check while the app stays open does not interrupt
- **WHEN** the app returns to the foreground long after the last check and a newer build exists
- **THEN** the availability is refreshed without opening a dialog

### Requirement: Pending update is reachable from Home

While an update is available, the Home screen SHALL show an entry that opens the update
dialog, so a postponed update can be started without restarting the app. When no update
is available the entry SHALL NOT be shown.

#### Scenario: Entry appears while an update is pending
- **WHEN** an update is available and the user is on Home
- **THEN** the "Sessão" group shows an "Atualizar app" entry

#### Scenario: Entry opens the dialog
- **WHEN** the user taps "Atualizar app"
- **THEN** the update dialog opens

#### Scenario: No entry when up to date
- **WHEN** no update is available
- **THEN** the "Sessão" group has no update entry

### Requirement: Download with progress and cancellation

The app SHALL download the APK into its private cache directory, reporting progress,
and SHALL let the user cancel the download. A cancelled or failed download SHALL leave
the app in a state from which the update can be retried.

#### Scenario: Progress is reported
- **WHEN** the download is running
- **THEN** the dialog shows the fraction downloaded

#### Scenario: User cancels
- **WHEN** the user cancels during the download
- **THEN** the download stops and the partial file is removed
- **AND** the update remains available to start again

#### Scenario: Network failure
- **WHEN** the download fails
- **THEN** the dialog shows an error with a retry action

### Requirement: Integrity verification before installation

The app SHALL verify the downloaded file against `latest.json` before installing: the
size SHALL equal `size` and the SHA-256 SHALL equal `sha256`. A file that fails either
check SHALL be deleted and SHALL NOT be passed to the installer.

#### Scenario: Verified file proceeds to installation
- **WHEN** the downloaded file matches `size` and `sha256`
- **THEN** the app proceeds to launch the installer

#### Scenario: Corrupted file is discarded
- **WHEN** the downloaded file's SHA-256 differs from `sha256`
- **THEN** the file is deleted
- **AND** the dialog reports the failure and offers to retry
- **AND** the installer is not launched

#### Scenario: Already downloaded file is reused
- **WHEN** a file for the published APK already exists in the cache and passes verification
- **THEN** the app skips the download and proceeds to installation

### Requirement: Installation through the system installer

The app SHALL hand the verified APK to the Android package installer through a
content URI with temporary read permission. The app SHALL declare the permission to
request package installs. If the user leaves the system installer without installing,
the dialog SHALL still offer to install the already verified file.

#### Scenario: Installer is launched
- **WHEN** verification succeeds
- **THEN** the system package installer opens for the downloaded APK

#### Scenario: User backs out of the installer
- **WHEN** the user cancels the system installer and returns to the app
- **THEN** the dialog offers to install again without downloading again

### Requirement: Failures of the check are silent

A failed update check SHALL NOT show any dialog, toast or error state and SHALL NOT
affect any other part of the app. The failure SHALL only be logged.

#### Scenario: Channel unreachable
- **WHEN** the app cannot reach the update channel
- **THEN** the app behaves exactly as when no update exists

#### Scenario: Offline startup
- **WHEN** the device has no connectivity at startup
- **THEN** no connectivity warning is shown because of the update check

### Requirement: Stale downloads are cleaned up

The app SHALL remove APK files left in its update cache that do not correspond to the
currently published APK, so old downloads do not accumulate on the device.

#### Scenario: Old APK is removed
- **WHEN** a check completes and the cache holds an APK with a different file name than `latest.json`'s `apk`
- **THEN** that file is deleted

#### Scenario: Cache is emptied once the app is up to date
- **WHEN** a check completes and the installed build is not older than the published one
- **THEN** every file in the update cache is deleted, including the published APK

### Requirement: Release APK targets ARM devices

The pipeline SHALL build the release APK for the ARM ABIs used by the collectors
(`armeabi-v7a` and `arm64-v8a`) and SHALL NOT include `x86_64`.

#### Scenario: Published APK has no x86_64 code
- **WHEN** the pipeline publishes a release APK
- **THEN** it contains native libraries only for `armeabi-v7a` and `arm64-v8a`
