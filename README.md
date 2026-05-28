<h1 align="center">
  <br>
  FloraScan
  <br>
</h1>

<h3 align="center">Point your camera at any plant. Know what it is in seconds.</h3>

<p align="center">
  <strong>Native iOS 26</strong> &nbsp;·&nbsp; <strong>Liquid Glass</strong> &nbsp;·&nbsp; <strong>Core ML + Pl@ntNet</strong> &nbsp;·&nbsp; <strong>Zero subscriptions</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS_26-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 26">
  <img src="https://img.shields.io/badge/Swift_6.2-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 6.2">
  <img src="https://img.shields.io/badge/SwiftUI-007AFF?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Core_ML-34C759?style=for-the-badge" alt="Core ML">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT">
</p>

<!--
<p align="center">
  <img src="docs/screenshots/identify.png" width="250">
  <img src="docs/screenshots/garden.png" width="250">
  <img src="docs/screenshots/detail.png" width="250">
</p>
-->

---

## What is FloraScan

FloraScan is a native iOS 26 plant identification and care management app. Snap a photo of any plant and get an instant identification powered by a hybrid engine that races an on-device Core ML model against the Pl@ntNet API (78,225+ species). Build your personal garden inventory, track watering and care schedules, and get smart reminders that adapt to the season and light conditions.

Built from scratch with SwiftUI, Liquid Glass, and strict Swift 6.2 concurrency. No third-party dependencies. No subscriptions. No tracking.

---

## Features

| | |
|---|---|
| **Identify** | Hybrid engine: Pl@ntNet API races against a Core ML model on-device. Local result appears instantly (~30ms), API upgrades it if better (~2s). Works offline with the local model. |
| **Garden** | 2-column grid with health rings, search, and context menus. Tap any card for a cinematic zoom transition into the full detail view. |
| **Care** | Smart scheduler adjusts watering intervals by season (summer -30%, winter +40%) and light level. Local notifications at 8:30 AM with one-tap actions. |
| **Share** | Export your entire garden as a `.florascan` file or share as an image snapshot. Import gardens from other users. |
| **Widget** | WidgetKit extension shows today's pending care tasks on the home screen (small and medium sizes). |
| **Design** | 30-token semantic color palette with full dark mode. WCAG AA contrast verified. VoiceOver, Dynamic Type, and Reduce Transparency supported. |

---

## How Identification Works

```
                   +----------------------+
   Camera --------+|  Pl@ntNet API        |---> 78,225 species
   capture         |  (async, ~2s)        |    score > 0.4 wins
                   +----------------------+
        |                                        |
        |          +----------------------+      v
        +--------->|  Core ML on-device   |---> chooseBestGuess()
                   |  (sync, ~30ms)       |    merges both results
                   +----------------------+
```

Both engines fire in parallel. The user sees the local result immediately. If the API returns a higher-confidence match, it upgrades seamlessly.

---

## Architecture

```
FloraScan/
  App/                    Design tokens, DI container, tab bar
  Core/
    Camera/             AVCaptureSession + UIViewRepresentable bridge
    ML/                 PlantClassifier actor + Vision framework
    Networking/         PlantNet, Perenual, Wikipedia clients
    Models/             Plant, PlantPhoto, CareTask (SwiftData)
    Scheduling/         Seasonal + light-adjusted care intervals
    Notifications/      Local notifications with custom actions
    Persistence/        ImageStore (LRU cache) + schema migrations
    Sharing/            Codable export/import with validation
  Features/
    Identify/           Camera + hybrid classification pipeline
    Garden/             Grid, search, hero zoom transitions
    PlantDetail/        Hero photo, care cards, notes, edit
    AddPlant/           3-step flow with auto-identify
    Today/              Grouped tasks, swipe-to-complete
    Onboarding/         3 pages over animated MeshGradient
    Share/              Export as .florascan or image
    Settings/           Attribution, data management
```

Strict concurrency throughout: `actor` for camera, classifier, and network clients. `@MainActor @Observable` for every ViewModel. Protocol-based dependency injection for testability.

---

## Quick Start

**Requirements:** macOS Tahoe + Xcode 26 + iPhone with iOS 26 (or Simulator)

```bash
git clone https://github.com/jlcl11/FloraScan.git
cd FloraScan
open FloraScan.xcodeproj
```

The app includes a free-tier Pl@ntNet API key and the Core ML model out of the box. Just build and run.

> To use your own API keys, edit `FloraScan/Resources/Secrets.plist` or copy `Secrets.plist.template` as a starting point. Get keys for free at [Pl@ntNet](https://my.plantnet.org) (500 ids/day) and [Perenual](https://perenual.com) (100 queries/day).

---

## Tech Stack

| Technology | Role |
|---|---|
| **Swift 6.2** | Strict concurrency with MainActor default isolation |
| **SwiftUI + Liquid Glass** | Native iOS 26 design language |
| **SwiftData** | Versioned schema with migration plan |
| **Core ML 9.0 + Vision** | On-device plant classification (~30ms) |
| **AVFoundation** | Camera capture pipeline with photo + video output |
| **UserNotifications** | Local reminders with custom action categories |
| **URLSession** | Async/await networking (no third-party deps) |
| **WidgetKit** | Home screen widget for today's care tasks |
| **Swift Testing** | @Test + #expect (no XCTest) |

---

## Attribution

[Pl@ntNet](https://plantnet.org) | [Perenual](https://perenual.com) | [Wikipedia REST API](https://en.wikipedia.org/api/rest_v1/)

---

<p align="center">
  MIT License - Built by <a href="https://github.com/jlcl11">Jose Luis Corral Lopez</a>
</p>
