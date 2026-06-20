# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

**Persistence:** `NSPersistentContainer` (local only). CloudKit migration is stubbed with TODO comments in `Persistence.swift` — switch to `NSPersistentCloudKitContainer` with container ID `iCloud.mannjaro.okaimono-app` when Apple Developer Program is active.

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
