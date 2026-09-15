# Firebase connection checkpoint

Owner direction, September 15: use the existing `maintainiac-aafec` project
with its existing billing account. The product is **Tame Your Biz**.
This supersedes the earlier separate-project direction in D34.

## Current bounded implementation

- Official `firebase_core` dependency; Android/iOS explicit client options from
  the latest owner downloads after Google provider enablement.
- Android application ID and iOS bundle ID: `com.tameyourbiz.app`.
- Apple configuration included in Runner resources and Google callback scheme.
- Android configuration retained in `android/app/google-services.json`.
  Core initialization uses explicit Dart options, not generated Gradle resources.
- SDK initialization is now deferred until the optional account screen opens.
  Local startup does not initialize Firebase. Failed initialization can be retried
  by another explicit account action; there is no automatic retry loop.
- Email/password Authentication added through an injected gateway. Dashboard
  settings has Your account: create, sign in, password reset, verify email,
  refresh verification, sign out, and delete the sign-in account.
- No Firestore, Storage, Analytics, or record upload code added.
- Existing local storage QA identity remains separate and skips Firebase.

Read-only 5.7 assessment: its Firebase options and cloud identity provider already
separate cloud identity from feature records. Retain that boundary; do not copy
its old bundle identifier or couple local startup to authenticated membership.

## Required next steps, not completed by this checkpoint

- Firebase CLI authorization remains incomplete. Console login is separate.
- Android download contains a web OAuth client but no Android OAuth client.
  Register debug and eventual Play signing certificate SHA fingerprints, download
  updated configuration, then implement and test native Google sign-in.
- Verify email/password against an owner-controlled live test account, add Apple
  and Google authentication flows, verified company membership,
  invitations, access revocation and emulator-tested server rules before sync.
- Account failures now surface in the account screen. Windows account connection
  remains unavailable rather than using an incorrect platform registration.
- Configure web/macOS registrations separately; do not reuse Android app IDs.
- Firebase Flutter Windows support is documented as development-only. Choose
  a supported production desktop access architecture before Windows cloud release.
- No App Check enforcement, cloud rules, cloud deployment, billing plan changes,
  trial policy, or device fingerprinting was performed in this slice.
- Pricing and trial lengths are exploratory, not implemented requirements.

New app IDs create a separate installed app/data container; old UI Lab local data
is not automatically migrated. The owner identified current device data as demo.
The existing SQLite storage implementation was not changed.

## Verification

Six focused automated tests pass for initialization idempotence, explicit retry,
graceful local
startup after an SDK error, skipped Windows/storage-QA connections, account form
validation/duplicate request prevention, and narrow layout with larger text.
The initial core connection built on Windows and Android; Android installed and
launched on the S24 Ultra. The account screen Android build also passed.
Final Tame Your Biz branding builds passed on Android and Windows. Full Flutter
analysis reports no issues; all six focused account/connection tests pass.
The final Android APK was installed and launched successfully on the S24 Ultra;
Windows was launched with the Tame Your Biz title for owner review.
Idle task-owned Gradle/Kotlin workers were stopped after validation.
SDK link warnings about missing debug PDB
files and existing untranslated localization warnings are not release acceptance.
iOS compilation and sign-in verification require the Mac and remain pending.

The account screen is not company onboarding and does not grant business-record
permissions. Its deletion action only deletes an Authentication identity; before
adding cloud company ownership it must be replaced with a complete owner-transfer
and data-retention deletion workflow. Signing in does not claim or upload existing
local records. Never expose those records as shared company data without the
pending installation-to-company binding and verified membership implementation.

Reference: https://firebase.google.com/docs/flutter/setup

## Product identity

Visible application titles, Android/iOS launcher labels, the Windows window and
product description, web manifest/title, localized notification wording, and PDF
creator metadata use Tame Your Biz. Internal Dart package names, existing local
storage identifiers, the Windows executable name and notification identity are
retained for compatibility. These internal values are not a second product name.
macOS display metadata is updated; the Mac build and application bundle migration
remain unverified. No app-store listing or Firebase project identifier was renamed.

## Owner testing direction

Start with approximately five to ten regular testers before expanding the group.
Before release, simulate a real company across the owner's computers and phones:
different employees, permissions, shared records, offline operation, reconnection,
revoked access, concurrent changes and complete daily work flows. These tests are
required work, not evidence already obtained. Larger tester counts, trial lengths
and prices are still undecided. Abuse prevention must respect privacy and Apple
and Google platform requirements; await the owner's upcoming details rather than
implementing device fingerprinting based on exploratory discussion.
