# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Ground rule

開発者はSwiftの初心者であり、現在このアプリの開発を通じて学習を行っています。
そのため、あなたは具体的な実装は行わず、方針だけ示してください。
ただし、開発者から明示的に実装を求められた場合は、その限りではありません。

## Project overview

**おかいものアプリ** — an iOS shopping list app built with SwiftUI and Core Data. The app lets users create named shopping lists, add menu items (献立) to each list, and manage ingredients (材料) per menu item with check-off support.

## Build and run

Use XcodeBuildMCP tools (preferred) or `xcodebuild` directly.

```bash
# Build and run on simulator (XcodeBuildMCP session defaults are pre-configured)
# Project: okaimono-app.xcodeproj, Scheme: okaimono-app, Simulator: iPhone 17 Pro

# Via xcodebuild CLI
xcodebuild -project okaimono-app.xcodeproj -scheme okaimono-app -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild test -project okaimono-app.xcodeproj -scheme okaimono-app -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

XcodeBuildMCP session defaults are stored in `.xcodebuildmcp/config.yaml` — simulator workflow only is enabled.

## Architecture

Three-tier Core Data hierarchy:

```
ShoppingList  →  MenuItem  →  Ingredient
  (買い物リスト)    (献立)        (材料)
```

Each entity is a hand-written `NSManagedObject` subclass (no Xcode-generated code). Relationships:
- `ShoppingList.menus: NSSet<MenuItem>` — one-to-many
- `MenuItem.ingredients: NSSet<Ingredient>` — one-to-many
- Sorted array accessors (`menusArray`, `ingredientsArray`) sort by `createdAt` ascending

**Persistence:** `NSPersistentCloudKitContainer` with container ID `iCloud.mannjaro.okaimono-app`.

**Navigation flow:**
1. `ContentView` — list of `ShoppingList` records, sorted newest-first
2. `ShoppingListDetailView` — `MenuItem` rows for a single list, inline `TextField` to add items
3. `IngredientView` (modal sheet) — `Ingredient` rows for a single menu item, check/uncheck support, inline add form with name + quantity fields

All views inject `managedObjectContext` via SwiftUI environment and use `@FetchRequest` with predicate-scoping per parent entity.

## Core Data model

The model file is `okaimono_app` (`.xcdatamodeld` managed by Xcode). Entity attributes:

| Entity | Attributes |
|--------|-----------|
| `ShoppingList` | `id: UUID`, `name: String?`, `createdAt: Date?` |
| `MenuItem` | `id: UUID`, `name: String?`, `createdAt: Date?` |
| `Ingredient` | `id: UUID`, `name: String?`, `quantity: String?`, `isChecked: Bool`, `createdAt: Date?` |

## Cursor Cloud specific instructions

**This project cannot be built, tested, or run on Cursor Cloud agents.** Cloud agent VMs run Linux (Ubuntu x86_64), but this is a native Apple-platform app that requires **macOS + Xcode + the iOS Simulator**:

- Sources import `SwiftUI`, `CoreData`, and `XCTest`, and persistence uses `NSPersistentCloudKitContainer` (CloudKit) with container `iCloud.mannjaro.okaimono-app`. These are closed-source Apple frameworks that ship only with Xcode on macOS.
- The build system is `okaimono-app.xcodeproj` driven by `xcodebuild` / XcodeBuildMCP against an iOS Simulator (iPhone 17 Pro). There is no `Package.swift`, so there is no cross-platform Swift Package Manager path.
- The open-source Swift-for-Linux toolchain does not help: it provides only the standard library and swift-corelibs-Foundation, not `SwiftUI`, `CoreData`, `CloudKit`, or the iOS SDK, and there is no iOS Simulator on Linux. The test target also uses `@testable import okaimono_app`, so tests require the full app module (SwiftUI/CoreData) to compile.

There is **no update script** and no Linux dependency setup that enables development here. Build, lint, test, and run must be done on a macOS machine (or a macOS CI runner) using the commands in the **Build and run** section above.
