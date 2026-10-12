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

//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        DispatchQueue.main.async {
//            if let window = view.window {
//                onResolve(window)
//            }
//        }
//        return view
    func makeNSView(context: Context) -> ResolverView {
        let view = ResolverView()
        view.onResolve = onResolve
        return view
    }

//    func updateNSView(_ nsView: NSView, context: Context) {
//        DispatchQueue.main.async {
//            if let window = nsView.window {
//                onResolve(window)
//            }
//        }
    func updateNSView(_ nsView: ResolverView, context: Context){
        // クロージャ自体は毎回更新するが、実際の通知は
        // viewDidMoveToWindow() が呼ばれた時のみ行う
        nsView.onResolve = onResolve
    }
    /// ウィンドウに実際にアタッチされたタイミングでのみ onResolve を呼ぶ NSView。
    /// SwiftUI の再描画のたびに呼ばれていた旧実装は、毎秒の時計更新のたびに
    /// NSWindow のプロパティを再設定することになり、AppKit側のレイアウト
    /// 再入警告（"layoutSubtreeIfNeeded"）の原因になっていた。
    final class ResolverView: NSView{
        var onResolve: ((NSWindow)->Void)?
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window{
                onResolve?(window)
            }
        }
    }
}
