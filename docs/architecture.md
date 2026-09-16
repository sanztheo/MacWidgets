# Architecture and operational contracts

[README](../README.md) · [Setup](setup.md) · [Design](design/README.md) · [Validation](validation.md)

## Targets

`MacWidgets` is the host app. `MacWidgetsExtension` contains the GitHub and Google
Calendar widgets. Core models, service clients, views and calendar actions are
compiled into both targets. There are no runtime packages or remote backend.

- `Sources/Core`: calendar math and snapshot models.
- `Sources/Services`: HTTP, GitHub GraphQL, Google APIs, Keychain and shared cache.
- `Sources/Design`: the same SwiftUI views used by the app gallery and WidgetKit.
- `Sources/App`: connections, OAuth browser callback and previews.
- `Sources/Widgets`: timeline providers, widget declarations and calendar intents.

## Data flow

The host app connects accounts and saves credentials to the macOS Keychain with
an ACL limited to the signed app and extension. A widget's timeline provider reads those credentials, fetches
service data if its snapshot is older than 15 minutes, and atomically writes the
snapshot into the shared App Group container. It then returns the snapshot and
any failure message to WidgetKit. This also works while the host app is closed,
provided signing and Keychain access are valid.

No token or raw API response is logged. The cache contains calendar/PR titles,
times and links, so it is private data. Cache files have mode 0600 and are not
inside the repository. Account disconnects remove the corresponding cache.

The Keychain implementation intentionally uses `SecItem` against the macOS
file-based Keychain, with `SecAccess` for the two-app ACL. Those ACL constructors
are deprecated but remain supported by the documented macOS Keychain model.
They avoid requiring a provisioned Keychain Access Group for local development.
The ACL must never be replaced with a list trusting every application. A future
move to the data-protection Keychain requires profiles for both binaries and an
explicit migration of existing credentials; adding the restricted entitlement
without profiles prevents launch. See [Apple TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains).

## Calendar

Monday-first Gregorian calendar in the Mac's current time zone. Events are fetched
for the entire displayed month with Google recurring events expanded. Page tokens
are followed for events, task lists and tasks; incomplete pages are not presented
as complete results. All-day end dates are exclusive. Timed events spanning
midnight appear on each overlapping day. Google Tasks due values are date-only,
even though their API representation resembles a UTC timestamp.

Date buttons perform an App Intent that stores the selected day before WidgetKit
reloads. A fresh month snapshot makes subsequent day selection local. Navigating
to an uncached month fetches that month's data. Calendar cache filenames include
the time zone to avoid reusing all-day timestamps interpreted in another zone.
Selection returns to today after midnight. The next requested reload is no later
than midnight, but actual scheduling remains a macOS decision.

All Calendar widget instances currently share the selected day. Separate
per-instance calendars or date selections are not implemented. The widget shows
the **primary Google calendar**, not every shared calendar. Tasks displayed are
incomplete tasks due on the selected day; undated/overdue tasks are not shown as
that day's tasks. The circle is a link to Google Tasks, not a completion toggle.
No write scope or task mutation is implemented.

## GitHub

One GraphQL query reads the connected user's latest 100 open authored PRs plus
the total accessible count. The widget displays only the number of rows fitting
its size. CI state comes from the latest commit's status-check rollup. A green
check means CI checks succeeded; it does not mean approval or merge readiness.
Drafts have a distinct indicator. Links must use HTTPS and github.com.

## Failure handling

Missing credentials, Keychain errors, network errors, denied permissions and
GraphQL partial errors remain visible. Previously fetched data can be shown with
an error, but never substituted with sample data. Gallery previews are the only
place for `PreviewData`. Credential changes are checked again before a pending
request can publish its snapshot. Google token refresh preserves a refresh token
when the refresh response omits one.

## Relevant documentation

- [Creating a widget extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [Interactive widgets](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
- [Widget backgrounds](https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background)
- [GitHub GraphQL schema](https://docs.github.com/en/graphql/overview/public-schema)
- [Google event listing](https://developers.google.com/workspace/calendar/api/v3/reference/events/list)
- [Google Tasks listing](https://developers.google.com/workspace/tasks/reference/rest/v1/tasks/list)
