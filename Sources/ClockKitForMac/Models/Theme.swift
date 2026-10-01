//
//  Theme.swift
//  ClockKitForMac
//
//  表示テーマ。FRQ-005 / DD-001 MOD-003(ThemeManager) に対応する。
//
import Foundation

enum Theme: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case system
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "ライト"
        case .dark: return "ダーク"
        case .system: return "システムに合わせる"
        case .custom: return "カスタム"
        }
    }
}
