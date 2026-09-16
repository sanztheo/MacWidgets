#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/checks
swiftc -swift-version 6 -parse-as-library -o .build/checks/core-checks \
  Sources/Core/*.swift Sources/Services/HTTP.swift Sources/Services/GitHubClient.swift \
  Sources/Services/GoogleCalendarClient.swift Tests/CoreChecks.swift
.build/checks/core-checks
swiftc -swift-version 6 -parse-as-library -typecheck \
  Sources/Core/*.swift Sources/Services/*.swift Sources/Design/*.swift \
  Sources/Widgets/CalendarIntents.swift Sources/App/*.swift
swiftc -swift-version 6 -parse-as-library -application-extension -typecheck \
  Sources/Core/*.swift Sources/Services/*.swift Sources/Design/*.swift Sources/Widgets/*.swift
