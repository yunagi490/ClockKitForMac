//
//  ClockWindowController.swift
//  ClockKitForMac
//
//  MOD-005: メインウィンドウのライフサイクル管理。
//  フロートモード（NSWindowLevel.floating）切替を行う。
//
//  [実装メモ] DD-001 に本モジュールの詳細設計シートが存在しないため、
//  基本設計書 FRQ-008・SCR-SPEC-001（ナイトスタンド外観仕様）に基づいて
//  実装している。SwiftUI の Window シーンが生成する NSWindow を
//  WindowAccessor 経由で取得し、AppKit レベルの見た目・振る舞いを設定する。
//
import AppKit
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "ClockWindowController")

@MainActor
final class ClockWindowController {

    private weak var window: NSWindow?

    /// SwiftUI 側から取得した NSWindow を設定し、ナイトスタンド外観・
    /// 挙動を適用する。
    func attach(to window: NSWindow, floatWindowEnabled: Bool) {
        guard self.window !== window else {
            // 既に設定済みなら float 状態のみ更新する。
            setFloating(floatWindowEnabled)
            return
        }

        self.window = window

        // ナイトスタンド風の見た目：タイトルバーを透過させ、
        // 背景を全面暗色にする（背景色自体は SwiftUI View 側で描画）。
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 640, height: 400)

        // 前回のウィンドウ位置・サイズを自動的に記憶・復元する。
        window.setFrameAutosaveName("ClockKitMainWindow")

        setFloating(floatWindowEnabled)
    }

    /// フロートウィンドウモード（常に最前面）の ON/OFF を切り替える（FRQ-008）。
    func setFloating(_ enabled: Bool) {
        guard let window else {
            logger.debug("setFloating called before window attached")
            return
        }
        window.level = enabled ? .floating : .normal
    }

    /// メインウィンドウの表示/非表示を切り替える（MenuBarController から呼ばれる）。
    func toggleVisibility() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
}
