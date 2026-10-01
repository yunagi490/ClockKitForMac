//
//  MenuBarController.swift
//  ClockKitForMac
//
//  MOD-004: NSStatusItem を生成・管理する。メニューバーへの時刻テキスト
//  表示とクリックイベントを制御する。
//
//  [実装メモ] DD-001 に本モジュールの詳細設計シートが存在しないため、
//  IF-SPEC-001（IF-003）の疑似コード、および基本設計書 FRQ-007 の
//  記述に基づいて実装している。
//
import AppKit
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "MenuBarController")

@MainActor
final class MenuBarController: NSObject {

    private var statusItem: NSStatusItem?

    var onToggleWindow: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    /// メニューバーアイコンを生成する。生成に失敗した場合は
    /// ウィンドウモードのみで継続する（IF-003 エラー処理）。
    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = item.button else {
            logger.error("Failed to create NSStatusItem")
            return
        }

        button.title = "--:--"
        button.font = NSFont(name: "SF Mono", size: 12) ?? NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.action = #selector(didClickMenuBar)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        item.menu = nil  // メニューは右クリック時に動的生成する
        statusItem = item
    }

    /// メニューバーから撤去する（menuBarEnabled = false 時）。
    func teardown() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }

    /// ClockViewModel の menuBarTimeString を受け取り表示を更新する（1秒ごと）。
    func updateTime(_ timeString: String) {
        statusItem?.button?.title = timeString
    }

    @objc private func didClickMenuBar() {
        guard let event = NSApp.currentEvent else {
            onToggleWindow?()
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            onToggleWindow?()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "設定...", action: #selector(menuOpenSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "ClockKit を終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // メニューを1回表示した後は参照を外し、通常クリックに戻す。
        statusItem?.menu = nil
    }

    @objc private func menuOpenSettings() {
        onOpenSettings?()
    }
}
