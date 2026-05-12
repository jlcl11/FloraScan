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
  TODO: Add screenshots here for maximum impact.
  Recommended: 3 iPhone mockups side by side (Identify, Garden, Detail)

  <p align="center">
    <img src="docs/screenshots/identify.png" width="250">
    <img src="docs/screenshots/garden.png" width="250">
    <img src="docs/screenshots/detail.png" width="250">
  </p>
-->

---

## Why FloraScan

Apps like Greg, Planta, or PictureThis are cross-platform products with generic UIs.

FloraScan is **built exclusively for iOS 26** — not adapted, not ported, not wrapped.

Every screen uses the new design language: Liquid Glass floating controls over full-bleed camera feeds, animated MeshGradient backgrounds that breathe, cinematic zoom transitions between cards and detail views, and SF Symbols 7 with draw-on animations. This isn't a plant app with iOS polish — it's an iOS 26 showcase that happens to identify plants.

---

## At a Glance

```
80 Swift files  ·  ~7,000 lines  ·  0 third-party dependencies  ·  0 Combine imports
```

| | |
|---|---|
| **Identify** | Hybrid engine: Pl@ntNet API (78,225 species) races against a Core ML model on-device. Local result appears instantly (~30ms), API upgrades it if better (~2s). Works offline. |
| **Garden** | 2-column grid with health rings, search, context menus. Tap any card for a cinematic zoom into the full detail view. Export your entire garden as a `.florascan` file or share as image. |
| **Care** | Smart scheduler adjusts watering intervals by season (summer -30%, winter +40%) and light level. Local notifications at 8:30 AM with one-tap actions: Done or Tomorrow. |
| **Design** | 30-token semantic palette, 14 typography styles, 4-level elevation system. Full dark mode. WCAG AA contrast verified. VoiceOver, Dynamic Type, Reduce Transparency — all supported. |

---

## The Identification Pipeline

```
                   ┌──────────────────────┐
   Camera ────────►│  Pl@ntNet API        │──► 78,225 species
   capture         │  (async, ~2s)        │    score > 0.4 wins
                   └──────────────────────┘
        │                                        │
        │          ┌──────────────────────┐       ▼
        └─────────►│  Core ML on-device   │──► chooseBestGuess()
                   │  (sync, ~30ms)       │    merges both results
                   └──────────────────────┘
```

Both engines fire in parallel. The user sees the local result immediately. If the API returns a higher-confidence match, it upgrades seamlessly — no spinner, no wait.

---

## Architecture

```
FloraScan/
├── App/                    Design tokens, DI container, tab bar
├── Core/
│   ├── Camera/             AVCaptureSession actor + preview bridge
│   ├── ML/                 PlantClassifier actor, protocols
│   ├── Networking/         PlantNet · Perenual · Wikipedia clients
│   ├── Models/             Plant · PlantPhoto · CareTask (@Model)
│   ├── Scheduling/         Seasonal + light-adjusted care intervals
│   ├── Notifications/      Local notifications with custom actions
│   ├── Persistence/        ImageStore with LRU cache + schema migrations
│   ├── Sharing/            Codable export/import with validation
│   └── UI/                 HealthRing · AsyncPlantImage · MeshGradient
└── Features/
    ├── Identify/           Camera + hybrid classification pipeline
    ├── Garden/             Grid · search · hero zoom transitions
    ├── Today/              Grouped tasks · swipe-to-complete · badge
    ├── PlantDetail/        Hero photo · care grid · notes · edit
    ├── AddPlant/           3-step flow with auto-identify + confetti
    ├── Onboarding/         3 pages over animated MeshGradient
    ├── Share/              Export as .florascan or image
    └── Settings/           Attribution · data management
```

**Strict concurrency throughout.** `actor` for camera, classifier, and network clients. `@MainActor @Observable` for every ViewModel. Protocol-based DI for testability. Zero `DispatchQueue.main.async` calls.

---

## Quick Start

**Requirements:** macOS Tahoe + Xcode 26 + iPhone with iOS 26 (or Simulator)

```bash
git clone https://github.com/jlcl11/FloraScan.git
cd FloraScan
open FloraScan.xcodeproj
```

Create `FloraScan/Resources/Secrets.plist` with your free API keys:

```xml
<dict>
    <key>PlantNetAPIKey</key>
    <string>YOUR_KEY</string>
    <key>PerenualAPIKey</key>
    <string>YOUR_KEY</string>
</dict>
```

Get keys for free: [Pl@ntNet](https://my.plantnet.org) (500 ids/day) · [Perenual](https://perenual.com) (100 queries/day)

> Without API keys the app still works — the Core ML model handles identification offline.

---

## Built With

| | Technology | Why |
|---|---|---|
| **Language** | Swift 6.2 | Strict concurrency, `MainActor` default isolation |
| **UI** | SwiftUI + Liquid Glass | Native iOS 26 materials, no UIKit (except camera bridge) |
| **Data** | SwiftData | Versioned schema with migration plan |
| **ML** | Core ML 9.0 + Vision | On-device classification in ~30ms |
| **Camera** | AVFoundation | Full capture pipeline with photo + video output |
| **Notifications** | UserNotifications | Local, with custom action categories |
| **Network** | URLSession async/await | No Alamofire, no Combine |
| **Tests** | Swift Testing | `@Test` + `#expect`, not XCTest |

---

## Attribution

[Pl@ntNet](https://plantnet.org) · [Perenual](https://perenual.com) · [Wikipedia REST API](https://en.wikipedia.org/api/rest_v1/)

---

<p align="center">
  <sub>MIT License · Built by <a href="https://github.com/jlcl11">Jose Luis Corral Lopez</a></sub>
</p>
