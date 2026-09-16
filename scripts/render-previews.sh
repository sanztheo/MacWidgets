#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc -swift-version 6 -parse-as-library -o .build/render-previews \
  Sources/Core/*.swift Sources/Services/SharedStore.swift Sources/Design/*.swift \
  Sources/Widgets/CalendarIntents.swift Tests/RenderPreviews.swift
.build/render-previews
