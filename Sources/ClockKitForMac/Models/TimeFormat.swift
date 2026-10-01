//
//  TimeFormat.swift
//  ClockKitForMac
//
//  時刻表示形式。FRQ-003, FRQ-004 / DD-001 MOD-006 の
//  clockTimeFormat (UserDefaults) に対応する。
//
import Foundation

enum TimeFormat: String, Codable, CaseIterable, Identifiable {
    case hour24 = "HH:mm:ss"
    case hour12 = "hh:mm:ss"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hour24: return "24時間表示"
        case .hour12: return "12時間表示"
        }
    }
}
