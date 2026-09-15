# Android development signing

UI Lab 2.1 uses the application ID `com.maintainiac.ui_lab_2_1`.
Android updates require the same signing identity as the installed application.
Each computer's automatically generated debug key can be different.

On September 13, 2026, the installed phone APK's signing certificate was
compared with the Windows and Mac development keys. The Mac key matched;
the Windows default key did not. A private copy of the Mac development key
was placed in the Windows user's Android configuration directory, outside
this repository. The global Windows debug key was preserved.

`android/app/build.gradle.kts` reads the optional `uiLab.debugKeystore`
property from ignored `android/debug-signing.properties`. Set it to the absolute path
of that shared development keystore on each additional development computer.
Use forward slashes in Windows property paths. If a configured key is missing,
the build fails rather than silently signing with another identity. Without
this property, the normal Android debug signing configuration remains active.
Do not put this custom property in `local.properties`; Flutter regenerates it.

Never commit private keystores or local configuration. Verify an APK's public
signing certificate before replacing an existing installation. Do not solve a
signing mismatch by changing the app ID or uninstalling without owner direction.

This is development signing, not the production release-signing plan.
The inherited release build still uses the debug signing configuration and
must not be represented as a store-ready release.
