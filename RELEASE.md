# Releases

`v0.1.0` is the first non-prerelease in the pre-1.0 series. Consumers should pin a published release. It does not establish a permanent 1.0 API contract.

## Release procedure

1. Run strict Swift format, macOS package tests and iOS compilation on the release candidate.
2. Validate real consumer applications against the same code. Keep application-specific editing, persistence and visibility policy outside the package.
3. Record compiler versions and distinguish compilation, hidden rendering and native interaction checks. Do not infer VoiceOver coverage from accessibility labels alone.
4. Verify the release commit, create a GPG-signed tag and verify its signature.
5. Review the release notes and publish without replacing an existing tag. Consumers can then resolve the published version.

## Verification for 0.1.0

| Environment | Toolchain | Coverage |
| --- | --- | --- |
| Local Apple Silicon | Xcode 27.2, Swift 6.4.2 | Package tests, strict formatting and iOS 17 simulator source typechecking |
| Hosted Intel macOS | Xcode 26.3, Swift 6.2.4 | Package tests, strict formatting and iOS 17 simulator source typechecking |
| MIDI Router consumer | Xcode 27.2, Swift 6.4.2 | Package tests, Thread Sanitizer, universal application build and targeted native UI tests |
| kokoko consumer | Xcode 27.2, Swift 6.4.2 | Core checks and macOS/iOS application builds without migrating its editors |

Native macOS checks exercised menu keyboard selection and Escape, suppression of the menu-container focus ring, and acceptance or rejection of committed text. Hidden-window tests separately cover field lifecycle, external-value reconciliation, viewport resizing, clipping, queued callbacks and observer cleanup.

The package requires Swift 6, macOS 14 or iOS 17. The viewport-size reader is macOS-only. iOS runtime interaction, VoiceOver and iPad context gestures remain unverified. Context-menu invocation and focus-return policy remain application-owned.
