# Android development signing

UI Lab 2.1 uses the normal application ID `com.tameyourbiz.app`.
Android updates require the same signing identity as the installed application.
Each computer's automatically generated debug key can be different.

On September 13, 2026, the installed phone APK's signing certificate was
compared with the Windows and Mac development keys. The Mac key matched;
the Windows default key did not. A private copy of the Mac development key
was placed in the Windows user's Android configuration directory, outside
this repository. The global Windows debug key was preserved.

`android/app/build.gradle.kts` reads the required `uiLab.debugKeystore`
property from ignored `android/debug-signing.properties`. Set it to the absolute path
of that shared development keystore on each additional development computer.
Use forward slashes in Windows property paths. If a configured key is missing,
the build fails rather than silently signing with another identity. Without
this property, normal app builds fail. A configured key must also match the
verified shared certificate below. The explicitly selected `STORAGE_QA=true`
test identity may still use default signing when no shared key is configured;
that separate test identity is not a workaround for updating the normal app.
Do not put this custom property in `local.properties`; Flutter regenerates it.

## Verified shared setup — September 19, 2026

The original Mac development key was transferred to HP with recipient-encrypted
OpenSSL CMS. The encrypted transfer's hash and size were checked before local
decryption, and the certificate was checked afterward. The temporary transfer
server was stopped and its closed listener verified. Original keys were preserved.

Both machines now have ignored `android/debug-signing.properties` configuration:

- Mac: `uiLab.debugKeystore=/Users/rbbie/.android/debug.keystore`
- HP: `uiLab.debugKeystore=C:/Users/rjenk/.android/ui-lab-shared-development.keystore`
- Alias: `androiddebugkey`
- Public certificate SHA-256:
  `BDE55B812494EB3C0451C9011B53FEDA5BE6FE9546F48555915C2C5F766C4189`

HP `:app:signingReport` succeeded and reports that certificate for debug,
profile, release and debugAndroidTest. The missing-configuration check also
failed with the intended actionable message rather than choosing the HP default
key. Mac configuration and ignore status were verified by its Codex task;
its existing debug APK had already been verified against the same certificate.
No new phone installation was performed for this signing setup verification.

Git can carry the build safeguard and this guide, but not the private keystore
or machine-local configuration. The safeguard changes remain local to HP until
committed, pushed and pulled onto Mac. The Mac's explicit key configuration is
already in place independently of that future Git synchronization.

Never commit private keystores or local configuration. Verify an APK's public
signing certificate before replacing an existing installation. Do not solve a
signing mismatch by changing the app ID or uninstalling without owner direction.

This is development signing, not the production release-signing plan.
The inherited release build still uses the debug signing configuration and
must not be represented as a store-ready release.
