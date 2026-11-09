# Early release

The first candidate is `v0.1.0-rc.1`. It is a prerelease for evaluating the shared API, not a stable 1.0 contract. Consumers should pin a reviewed revision or candidate tag.

## Checklist

- [ ] Run strict Swift format, macOS package tests and iOS compilation on the candidate's CI commit.
- [ ] Verify at least two real consumer applications against the candidate revision.
- [ ] Record compiler versions and distinguish compile checks, hidden rendering and real input tests.
- [ ] Verify the commit signature, create a signed candidate tag and verify its signature.
- [ ] Review the release text before publishing a GitHub prerelease.

## Candidate notes

This candidate provides literal bracketed controls, stable-width tabs, opaque popup surfaces, frozen-anchor placement and in-window menu navigation. Applications retain their own commands, availability checks, presentation state and focus-return policy.

The package requires Swift 6, macOS 14 or iOS 17. Tests cover menu state and hidden macOS rendering, including tab geometry and independence from the host font. iOS verification is compilation only. Real pointer and keyboard delivery, VoiceOver behavior and iPad context interactions remain unverified. Context-menu invocation adapters are not included.
