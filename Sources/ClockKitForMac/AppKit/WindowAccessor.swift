//
//  WindowAccessor.swift
//  ClockKitForMac
//
//  SwiftUI の Window シーンが生成する NSWindow への参照を取得するための
//  補助ビュー。ClockWindowController に橋渡しするために使用する。
//  （SwiftUI 単体では NSWindow のレベル変更・タイトルバー非表示等の
//  AppKit固有の制御ができないための定番パターン）
//
import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onResolve(window)
            }
        }
    }
}
