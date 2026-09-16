# Validation status

[README](../README.md) · [Setup](setup.md) · [Architecture](architecture.md)

Initial implementation: 2026-09-16. This page distinguishes compilation from a
working installed widget and from public distribution.

Local Swift 6 core checks and both target typechecks passed on macOS 27. Native
SwiftUI renders were inspected, including a correction for a truncated date in
the large layout. The exact GitHub query was accepted by the live GraphQL API;
no private PR data was committed.

A development signing probe was blocked by macOS with an invalid-signature
message. It claimed a restricted Keychain Access Group without a provisioning
profile. That configuration has been removed in favor of the documented macOS
file-based Keychain ACL model. The blocked probe is not part of the repository
or an installation artifact. No Gatekeeper/XProtect setting was changed.

## Checks

`scripts/check.sh` compiles and runs focused checks for calendar grid alignment,
leap years, six-week months, DST, exclusive all-day ends, overnight events,
midnight selection reset, API date parsing, OAuth form encoding, GitHub partial
errors and unsafe links. It also typechecks the app and extension using Swift 6.

`scripts/render-previews.sh` generates the four calendar sizes using the actual
SwiftUI views. Inspect for truncated dates, overlapping agenda rows, six-week
months and missing empty/error states.

GitHub Actions packages the application and extension with Xcode and uploads an
unsigned development archive. The build must include the extension's App Intent
metadata. No signing certificate is uploaded by the workflow.

## Acceptance on a signed install

- Launch once; both widgets appear in the macOS desktop widget gallery.
- With the iPhone off, connect GitHub and compare the open authored count and
  links with GitHub; distinguish successful checks from approval.
- Connect Google; compare a recurring event, an all-day event and a dated task
  against the primary Google calendar and Google Tasks.
- Select a day without opening the app. Check that its agenda changes, then
  navigate into a previously uncached month.
- Close the host app and verify a later provider refresh can read shared Keychain
  credentials and update the widget.
- Check offline/stale data, revoked credentials and disconnect while a request
  is pending. No fictional or other-account data should replace real data.
- Inspect all four sizes in full color and macOS tinted appearance.

Live Google authorization, widget registration, shared-Keychain runtime behavior,
background refresh and notarized public distribution are not implied by local
core checks or a successful unsigned build. Record actual results here as they
are verified.
