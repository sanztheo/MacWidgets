# Setup

[Back to README](../README.md) · [Architecture](architecture.md) · [Validation](validation.md)

## Signing

The app and extension need the same Apple signing team and App Group.
`project.yml` derives the shared identifier from `DEVELOPMENT_TEAM`; it contains
no personal signing ID. Select your team on both targets in Xcode and use
automatic signing.

The macOS App Group uses `TEAMID.com.sanztheo.MacWidgets`. Apple supports this
team-prefixed naming convention on macOS without provisioning. Credentials use
the macOS file-based Keychain with an explicit access-control list containing
only the signed host app and embedded extension. This app does not claim the
restricted `keychain-access-groups` entitlement. Missing access is an explicit
connection error, never a fallback to unprotected credential files.

The unsigned CI archive is a development artifact. For public installation,
produce a Developer ID signed, notarized build with the matching entitlements,
and verify its widgets on a clean Mac. Do not disable Gatekeeper as an
installation procedure.

## GitHub

1. Open MacWidgets → Connexions.
2. Create a fine-grained personal access token for the repositories to display.
3. Grant read access to **Pull requests**, **Checks**, and **Commit statuses**;
   repository metadata access is implicit. Organization approval/SSO may also be
   required. Classic tokens require the corresponding private-repository scope.
4. Paste it into the secure field and connect. The app validates its query before
   storing the token in Keychain, then clears the field.

Only PRs authored by the connected account appear. The token's repository access
determines which private repositories can be queried. A GraphQL error is shown as
an error; it never becomes “zero PRs”.

## Google

This first source release uses a **user-supplied desktop OAuth client**. A shared,
verified Google OAuth application is not provisioned by this repository.

1. In [Google Cloud Console](https://console.cloud.google.com), create/select a project.
2. Enable **Google Calendar API** and **Google Tasks API**.
3. Configure the OAuth consent screen. In testing mode, add your Google account
   as a test user. Google may expire testing refresh tokens after seven days.
4. Create an OAuth client of type **Desktop app** and download its JSON file.
5. In MacWidgets → Connexions, import that file, then click **Se connecter avec Google**.
6. In your browser, grant the requested read-only calendar and task permissions.

The app uses PKCE (S256), an unpredictable state value and a temporary listener
bound only to `127.0.0.1` on a random port. No embedded browser, manual pasted
authorization code, or deprecated out-of-band flow is used. The listener closes
on completion, cancellation or timeout. The client configuration and tokens are
kept in Keychain. Never commit the downloaded JSON file.

Scopes:

- `https://www.googleapis.com/auth/calendar.events.readonly`
- `https://www.googleapis.com/auth/tasks.readonly`

For broader public adoption, a maintainer must configure a shared OAuth project
and complete any Google verification requirements. A public GitHub repository
does not perform that registration automatically.

## Refresh and disconnect

Widgets request refreshes every 15 minutes; macOS decides when to execute them.
Use **Actualiser** in the app for a user-triggered refresh. On network failure,
the previous snapshot remains visible with an error. Data older than one hour is
labeled. Disconnecting removes local tokens and cached service data and requests
a widget reload. Revoking server-side authorization remains available in your
Google or GitHub account settings.

References: [Apple App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups),
[Google desktop OAuth](https://developers.google.com/identity/protocols/oauth2/native-app),
[WidgetKit refresh policies](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).
