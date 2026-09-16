# Approved widget designs

[README](../../README.md) · [Architecture](../architecture.md)

Approved on 2026-09-16. These four ImageGen mockups are the visual reference:

| Format | Reference | WidgetKit family |
|---|---|---|
| Small square | [A](calendar-small.png) | `systemSmall` |
| Medium rectangle | [B](calendar-medium.png) | `systemMedium` |
| Large square | [C](calendar-large.png) | `systemLarge` |
| Large landscape rectangle | [D](calendar-wide.png) | `systemExtraLarge` |

Retain the dark charcoal background, rounded system container, white system
typography, muted secondary text, blue selected date, colored event markers, and
the month/agenda arrangements. The large square places its agenda below the
month; landscape formats place it to the right. The compact square shows only
the month. Native widget size and system tinting may change exact pixel values.

The GitHub layout follows the supplied PR reference: green pull-request symbol,
count and “created” heading, GitHub mark, muted repository/number line, bold title
and check status. Only authored pull requests are in scope.

Regenerate **actual SwiftUI renders**, separately from these reference images:

```sh
scripts/render-previews.sh
```

Output: `.build/previews/`. These are native view renders, not proof of widget
registration, background refresh, account connectivity, or App Intent execution.

ImageGen prompt set: native macOS dark Google Calendar widgets on a blue desktop;
September 2026, Monday-first grid, selected Wednesday 16, fictional “Point équipe”,
“Revue produit”, “Appel client” events and “Envoyer le devis” task. A month-only
square, a month/agenda medium rectangle, a stacked large square and a wide split
layout. Built-in image generation was used; no provider API key was required.
