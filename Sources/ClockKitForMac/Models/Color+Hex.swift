//
//  Color+Hex.swift
//  ClockKitForMac
//
//  "#RRGGBB" 形式の文字列と SwiftUI.Color を相互変換するヘルパー。
//  ThemeManager / AppSettings のカスタムテーマ色保存に使用する。
//
import SwiftUI
import AppKit

extension Color {
    /// "#RRGGBB" または "RRGGBB" 形式の文字列から Color を生成する。
    /// パースに失敗した場合は黒を返す。
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgb), hexString.count == 6 else {
            self = .black
            return
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// "#RRGGBB" 形式の文字列に変換する（UserDefaults 保存用）。
    var hexString: String {
        guard let cg = NSColor(self).usingColorSpace(.deviceRGB) else {
            return "#000000"
        }
        let r = Int((cg.redComponent * 255).rounded())
        let g = Int((cg.greenComponent * 255).rounded())
        let b = Int((cg.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
