# Distribution

TokenBar supports two distribution modes:

- ad-hoc signing for local builds and alpha testing;
- Developer ID signing plus Apple notarization for public releases.

The current public alpha is ad-hoc signed. Do not describe a release as
notarized until `Scripts/notarize.sh` completes successfully and the resulting
archive has replaced the release asset.

## One-time Apple setup

Public notarization requires:

1. an active Apple Developer Program membership;
2. Xcode with its license accepted;
3. a `Developer ID Application` certificate installed in Keychain Access;
4. a notarytool Keychain profile.

Accept the local Xcode license:

```bash
sudo xcodebuild -license
```

Create the notary profile locally. Use an app-specific password and never add
it, the Apple ID, or the Team ID to this repository:

```bash
xcrun notarytool store-credentials TokenBarNotary \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID"
```

## Build, sign and notarize

Find the exact certificate name:

```bash
security find-identity -v -p codesigning
```

Build with that identity:

```bash
TOKENBAR_SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
  Scripts/package.sh release
```

Submit, staple, validate and produce a clean archive:

```bash
TOKENBAR_NOTARY_PROFILE=TokenBarNotary Scripts/notarize.sh
```

The notarization script refuses ad-hoc signed apps. It also rebuilds the final
zip after stapling so offline Gatekeeper checks can find the ticket.

## Release checklist

- Run `swift test`.
- Build the arm64 Release app.
- Notarize and staple successfully.
- Confirm `spctl --assess` succeeds.
- Confirm the zip contains no `__MACOSX` directory.
- Verify the generated SHA-256 file.
- Test installation on a different Apple Silicon Mac.
- Update `CHANGELOG.md`, version values and release notes.
- Upload the notarized zip and checksum to GitHub Releases.

## Homebrew

`Packaging/tokenbar-for-codex.rb.template` is the source template for a future
Homebrew tap. Replace `__VERSION__` and `__SHA256__` only after publishing a
notarized release. A public `brew install --cask` command should not be
advertised before the tap exists and the download passes Gatekeeper.
