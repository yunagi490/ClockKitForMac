//
//  ThemeManager.swift
//  ClockKitForMac
//
//  MOD-003: ライト/ダーク/カスタムテーマとフォント設定を一元管理する。
//  NSAppearance 連動・フォント/サイズのバリデーションを担当する。
//  DD-001 MOD-003 に準拠。関連: FRQ-005, FRQ-006
//
import SwiftUI
import AppKit
import Combine
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "ThemeManager")

@MainActor
final class ThemeManager: ObservableObject {

    // MARK: - Published プロパティ（View が bind する）

    @Published private(set) var currentFont: Font = .custom("SF Mono", size: 128.0)
    @Published private(set) var textColor: Color = Color(hex: "#FF9500")
    @Published private(set) var backgroundColor: Color = Color(hex: "#1A1A1A")

    private let settings: SettingsStore
    private var cancellables: Set<AnyCancellable> = []
    private var appearanceObserver: NSObjectProtocol?

    init(settings: SettingsStore) {
        self.settings = settings

        settings.$current
            .removeDuplicates { $0.clockTheme == $1.clockTheme
                && $0.clockTextColor == $1.clockTextColor
                && $0.clockBgColor == $1.clockBgColor }
            .sink { [weak self] s in
                self?.applyTheme(s.clockTheme)
            }
            .store(in: &cancellables)

        settings.$current
            .removeDuplicates { $0.fontName == $1.fontName && $0.fontSize == $1.fontSize }
            .sink { [weak self] s in
                _ = self?.resolveFont(name: s.fontName, size: s.fontSize)
            }
            .store(in: &cancellables)

        applyTheme(settings.current.clockTheme)
        currentFont = resolveFont(name: settings.current.fontName, size: settings.current.fontSize)
        observeAppearanceChange()
    }

    deinit {
        if let token = appearanceObserver {
            DistributedNotificationCenter.default().removeObserver(token)
        }
    }

    // MARK: - テーマ適用

    /// テーマを適用し Published プロパティを更新する。
    func applyTheme(_ theme: Theme) {
        switch theme {
        case .light:
            textColor = .black
            backgroundColor = .white
            NSApp.appearance = NSAppearance(named: .aqua)

        case .dark:
            textColor = Color(hex: "#FF9500")
            backgroundColor = Color(hex: "#1A1A1A")
            NSApp.appearance = NSAppearance(named: .darkAqua)

        case .system:
            // システム外観に追従
            NSApp.appearance = nil
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                textColor = Color(hex: "#FF9500")
                backgroundColor = Color(hex: "#1A1A1A")
            } else {
                textColor = .black
                backgroundColor = .white
            }

        case .custom:
            textColor = Color(hex: settings.current.clockTextColor)
            backgroundColor = Color(hex: settings.current.clockBgColor)
        }
    }

    /// バリデーション済みの SwiftUI Font を返す（FRQ-006）。
    /// 未知のフォント名は "SF Mono" にフォールバックする。
    @discardableResult
    func resolveFont(name: String, size: Double) -> Font {
        let clampedSize = max(24.0, min(256.0, size))
        if clampedSize != size {
            logger.warning("fontSize clamped: \(size, privacy: .public) -> \(clampedSize, privacy: .public)")
        }

        let resolvedFont: Font
        // if NSFont(name: name, size: clampedSize) != nil {
            // resolvedFont = Font.custom(name, size: clampedSize)
            // NSFont(name: )はPostScript名(例: "SFMono-Regular")を要求するが
            // フォント選択ドロップダウンは NSFontManager.availableFontFamilies の
            // ファミリー名（例: "SF Mono"）を渡してくる。両者は一致しないため、
            // ファミリー名ベースで解決できる NSFontManager.font(withFamily:) を使う。
            if let nsFont = NSFontManager.shared.font(withFamily: name, traits: [], weight: 5, size: clampedSize){
                resolvedFont = Font(nsFont)
        } else {
            // logger.warning("Font not found: \(name, privacy: .public), fallback to SF Mono")
            // resolvedFont = Font.custom("SF Mono", size: clampedSize)
            // ここでカスタムフォント名に再度フォールバックすると同じ理由で
            // 解決に失敗し続ける可能性があるため、必ず解決できる
            // システム標準の等幅フォントにフォールバックする。
            logger.warning("Font family not found: ¥(name, privacy: .public), fallvack to system monospaced")
            resolvedFont = .system(size: clampedSize, design: .monospaced)
        }

        currentFont = resolvedFont
        return resolvedFont
    }

    // MARK: - システム外観連動

    /// NSAppearanceDidChangeNotification 相当（システム外観変更）を購読する。
    /// システムのダーク/ライト切替は DistributedNotificationCenter 経由で
    /// 通知される（AppleInterfaceThemeChangedNotification）。
    private func observeAppearanceChange() {
        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.settings.current.clockTheme == .system else { return }
            self.applyTheme(.system)
        }
    }
}
