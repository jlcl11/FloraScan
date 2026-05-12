//
//  Font+Tokens.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

nonisolated extension Font {
    // ─── Sans-serif scale ───────────────────────────────────
    static let fsDisplay = Font.system(size: 44, weight: .bold, design: .default)
    static let fsLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let fsTitle1 = Font.system(size: 28, weight: .bold, design: .default)
    static let fsTitle2 = Font.system(size: 22, weight: .bold, design: .default)
    static let fsTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let fsHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let fsBody = Font.system(size: 17, weight: .regular, design: .default)
    static let fsCallout = Font.system(size: 16, weight: .medium, design: .default)
    static let fsSubhead = Font.system(size: 15, weight: .medium, design: .default)
    static let fsFootnote = Font.system(size: 13, weight: .medium, design: .default)
    static let fsCaption1 = Font.system(size: 12, weight: .medium, design: .default)
    static let fsCaption2 = Font.system(size: 11, weight: .semibold, design: .default)
    static let fsMonoCap = Font.system(size: 11, weight: .medium, design: .monospaced)

    // ─── Serif italic (scientific names) ────────────────────
    static let fsSciSmall = Font.custom("NewYorkItalic", size: 13, relativeTo: .footnote)
    static let fsSciDefault = Font.custom("NewYorkItalic", size: 17, relativeTo: .body)
    static let fsSciLarge = Font.custom("NewYorkItalic", size: 22, relativeTo: .title2)
    static let fsSciHero = Font.custom("NewYorkItalic", size: 28, relativeTo: .title)

    // ─── Semantic aliases used in SCREENS.md ────────────────
    static let scientificName = fsSciSmall
    static let scientificNameDefault = fsSciDefault
    static let scientificNameLarge = fsSciLarge
}
