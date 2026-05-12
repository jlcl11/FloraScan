//
//  Theme.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

// MARK: - Palette (30 semantic tokens)

nonisolated enum Palette {
    // ─── Brand core ─────────────────────────────────────────
    static let leaf900 = Color(hex: "#082E1F")
    static let leaf700 = Color(hex: "#0E5C3F")       // PRIMARY — 7.1:1 on cream
    static let leaf500 = Color(hex: "#2F8262")        // active/interactive — 4.6:1
    static let leaf300 = Color(hex: "#5DA271")        // decorative soft
    static let leaf100 = Color(hex: "#C7DCC9")        // tinted bg

    static let amber700 = Color(hex: "#B57828")       // accent text — 4.6:1
    static let amber500 = Color(hex: "#E6A85C")       // ACCENT HERO — bg only, never text
    static let amber200 = Color(hex: "#F4D9A8")       // soft tint

    static let clay700 = Color(hex: "#A24A3A")        // critical textual — 5.1:1
    static let clay500 = Color(hex: "#C95252")        // alert decorative
    static let clay200 = Color(hex: "#F2C5BD")        // tint

    // ─── Care semantic (WCAG refined) ───────────────────────
    static let careWater = Color(hex: "#4E78B0")
    static let careWaterSoft = Color(hex: "#7B9ACC")
    static let carePrune = Color(hex: "#6F5734")
    static let carePruneSoft = Color(hex: "#8B6F47")
    static let careFertilize = Color(hex: "#6F4F90")
    static let careFertilizeSoft = Color(hex: "#9B7BB8")
    static let careRepot = Color(hex: "#9C5635")
    static let careRepotSoft = Color(hex: "#C77B5C")

    // ─── Surface (light mode) ───────────────────────────────
    static let surfaceApp = Color(hex: "#F5F1E8")
    static let surfaceCard = Color(hex: "#FFFFFF")
    static let surfaceElev = Color(hex: "#FBF8F1")
    static let surfaceTinted = Color(hex: "#EDE7D7")

    // ─── Text on light ──────────────────────────────────────
    static let textPrimary = Color(hex: "#1A1612")       // 14.6:1 AAA
    static let textSecondary = Color(hex: "#4A4640")     // 7.8:1 AAA
    static let textTertiary = Color(hex: "#7A766F")      // 4.6:1 AA
    static let textQuaternary = Color(hex: "#B0ACA4")    // decorative only
    static let textOnLeaf = Color(hex: "#FFFFFF")        // on leaf-700
    static let textOnAmber = Color(hex: "#1A1612")       // on amber-500

    // ─── Borders / dividers ─────────────────────────────────
    static let borderSubtle = Color.black.opacity(0.08)
    static let borderDefault = Color.black.opacity(0.14)
    static let borderStrong = Color.black.opacity(0.22)
    static let dividerHair = Color.black.opacity(0.06)

    // ─── Status semantic (alias) ────────────────────────────
    static let statusOk = leaf500
    static let statusWarning = amber700
    static let statusCritical = clay700

    // ─── Aliases ────────────────────────────────────────────
    static let primary = leaf700
    static let accent = amber500
    static let healthOk = leaf500
    static let healthWarning = amber700
    static let healthCritical = clay700

    // ─── Care type aliases for CareType extension ───────────
    static let watering = careWater
    static let pruning = carePrune
    static let fertilizing = careFertilize
    static let repotting = careRepot
}

// MARK: - Dynamic (light/dark adaptive tokens)

extension Palette {
    nonisolated enum Dynamic {
        static let surfaceApp = Color(light: "#F5F1E8", dark: "#0F1411")
        static let surfaceCard = Color(light: "#FFFFFF", dark: "#1A211C")
        static let surfaceElev = Color(light: "#FBF8F1", dark: "#222A24")
        static let surfaceTinted = Color(light: "#EDE7D7", dark: "#2A332C")

        static let textPrimary = Color(light: "#1A1612", dark: "#F1EDE2")
        static let textSecondary = Color(light: "#4A4640", dark: "#C2BDB1")
        static let textTertiary = Color(light: "#7A766F", dark: "#8E8A80")
        static let textOnLeaf = Color(light: "#FFFFFF", dark: "#F1EDE2")

        static let primary = Color(light: "#0E5C3F", dark: "#2F8262")
        static let accent = Color(light: "#E6A85C", dark: "#F0BF7E")
        static let critical = Color(light: "#A24A3A", dark: "#E08070")

        static let careWater = Color(light: "#4E78B0", dark: "#8FB3E0")
        static let carePrune = Color(light: "#6F5734", dark: "#B79567")
        static let careFertilize = Color(light: "#6F4F90", dark: "#B89AD4")
        static let careRepot = Color(light: "#9C5635", dark: "#DC9C7A")
    }
}
