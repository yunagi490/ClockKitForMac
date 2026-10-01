# ClockKit for Mac

macOS 向けネイティブ デジタル時計アプリ。要件定義書(REQ-001)〜結合テスト仕様書(IT-SPEC-001)
の設計書一式に基づいて実装したソースコード一式です。

- **UI**: iPhoneナイトスタンドモード風。左ペイン：大型デジタル時計、右ペイン：月間カレンダー
- **アーキテクチャ**: MVVM（Swift 5.9 / SwiftUI + AppKit、C++17 高精度タイマー、Objective-C++ ブリッジ）
- **対応OS**: macOS 13 Ventura 以降 / Apple Silicon・Intel Universal Binary

## セットアップ

このリポジトリは `.xcodeproj`（バイナリに近く差分が追いづらい）をGit管理せず、
[XcodeGen](https://github.com/yonaskolb/XcodeGen) の `project.yml` からその都度
プロジェクトファイルを生成する方式を採っています。

```bash
# 初回のみ
brew install xcodegen

# プロジェクト生成 → Xcodeで開く
cd ClockKitForMac
xcodegen generate
open ClockKitForMac.xcodeproj
```

XcodeGen を使わず手動で Xcode プロジェクトを作りたい場合は、新規 macOS App
ターゲット（Swift, SwiftUI）を作成し、`Sources/ClockKitForMac` 以下のファイルを
ターゲットに追加した上で、Build Settings で以下を設定してください。

- Objective-C Bridging Header: `Sources/ClockKitForMac/ClockKitForMac-Bridging-Header.h`
- C++ Language Dialect: `C++17`
- Info.plist: `Resources/Info.plist` を使用（`NSCalendarsUsageDescription` 必須）
- Entitlements: `Resources/ClockKitForMac.entitlements`（App Sandbox 有効）
- Deployment Target: macOS 13.0

## ビルド要件

- Xcode 15 以降
- macOS 13 Ventura 以降の実機・シミュレータ環境

## モジュール構成（DD-001 対応表）

| モジュールID | クラス / ファイル | 言語 | 実装パス |
|---|---|---|---|
| MOD-001 | ClockEngine | C++17 | `Sources/ClockKitForMac/ClockEngine/ClockEngine.{hpp,cpp}` |
| （ブリッジ） | ClockEngineBridge | Obj-C++ | `Sources/ClockKitForMac/ClockEngine/ClockEngineBridge.{h,mm}` |
| MOD-002 | ClockViewModel | Swift | `Sources/ClockKitForMac/ViewModels/ClockViewModel.swift` |
| MOD-003 | ThemeManager | Swift | `Sources/ClockKitForMac/ViewModels/ThemeManager.swift` |
| MOD-004 | MenuBarController | Swift(AppKit) | `Sources/ClockKitForMac/AppKit/MenuBarController.swift` |
| MOD-005 | ClockWindowController | Swift(AppKit) | `Sources/ClockKitForMac/AppKit/ClockWindowController.swift` |
| MOD-006 | AppSettings | Swift(struct) | `Sources/ClockKitForMac/Settings/AppSettings.swift` |
| MOD-007 | CalendarViewModel | Swift | `Sources/ClockKitForMac/ViewModels/CalendarViewModel.swift` |
| MOD-008 | CalendarGridBuilder | Swift(struct) | `Sources/ClockKitForMac/ViewModels/CalendarGridBuilder.swift` |
| MOD-009 | NextEventFetcher | Swift(struct) | `Sources/ClockKitForMac/ViewModels/NextEventFetcher.swift` |
| MOD-010 | PermissionManager | Swift(actor) | `Sources/ClockKitForMac/ViewModels/PermissionManager.swift` |

画面（SCR-001〜004）は `Sources/ClockKitForMac/Views/` 以下、
App生成物（AppDelegate / DIコンテナ / エントリポイント）は `Sources/ClockKitForMac/App/` 以下です。

## 設計書との差異・補足事項

複数の設計書（REQ-001 / BD-001 / SCR-SPEC-001 / DD-001 / IF-SPEC-001 / API-SPEC-001 /
UT-SPEC-001 / IT-SPEC-001）を突き合わせた結果、いくつか記載の矛盾・欠落があったため、
以下の方針で補完・判断しています。実装後にご確認ください。

1. **BD-001 と SCR-SPEC-001/DD-001 のUI不一致**: BD-001（基本設計書）はカレンダー機能のない
   単純な時計アプリを記述していますが、SCR-SPEC-001（画面仕様書）と DD-001（詳細設計書、
   「REQ-001 v1.1 / SCR-SPEC-001 v1.1」参照と明記）はナイトスタンドモード＋EventKit連携を
   前提としています。後工程かつより詳細な DD-001 / SCR-SPEC-001 / IF-SPEC-001 /
   API-SPEC-001 を正として実装しました。
2. **MOD-004 / MOD-005 の詳細設計欠落**: DD-001 にはこの2モジュールの詳細設計シートが
   存在しません（モジュール一覧には記載あり）。IF-SPEC-001（IF-003）の疑似コードと
   BD-001 の機能概要（FRQ-007, FRQ-008）から実装しました。
3. **AppSettings キーの補完**: DD-001 の AppSettings 疑似コードが列挙するキー一覧には
   `clockTextColor` / `clockBgColor`（ThemeManager.applyTheme(.custom) が参照）、
   `showAmPm`（項目定義⑮ chkAmPm が参照）、`hasCompletedOnboarding`
   （初回起動判定に必須）が含まれていなかったため追加しています。
4. **オンボーディングのステップ数**: BD-001 / SCR-SPEC-001 は「表示設定→テーマ設定」の
   2ステップと記載していますが、IT-SPEC-001（SN-002, IT-SN002-01〜03）は
   Step1/Step2/Step3（カレンダー権限）の3ステップを前提にしたテストケースに
   なっているため、本実装では3ステップ（①表示形式 → ②テーマ → ③カレンダー権限）
   で実装しています。
5. **「次の予定」UI**: SCR-SPEC-001 の項目定義一覧（①〜⑩）には次の予定表示欄の
   項番が明記されていませんが、DD-001 MOD-009 / IT-SN006 はこの表示を前提と
   しているため、カレンダーペイン下部に追加しています。
6. **SettingsStore / AppEnvironment の追加**: DD-001 の AppSettings は
   `static load()` / `func save()` を持つ struct として定義されていますが、
   複数の ViewModel が同じ設定を監視・即時反映・即時永続化する必要があるため、
   `SettingsStore`（ObservableObjectラッパー）と `AppEnvironment`（DIコンテナ）を
   追加しています。AppSettings 自体の読み書きロジックは DD-001 の疑似コードの
   ままです。
7. **ウィンドウ管理**: SwiftUI の `Window` シーン（macOS13+）を採用し、
   `WindowAccessor`（NSViewRepresentable）経由で裏側の `NSWindow` を取得して
   `ClockWindowController` がフロートレベル等を制御する構成にしています。
8. **設定画面を開く操作**: macOS14+ の `openSettings` 環境アクションではなく、
   macOS13互換の `showSettingsWindow:` セレクタ送出を使用しています
   （本アプリの最低対応OSがmacOS13 Venturaのため）。
9. **launchAtLogin / windowFrame**: BD-001旧版にあった `launchAtLogin`
   （「将来拡張」と明記）は未実装です。`windowFrame` の手動UserDefaults保存も
   DD-001では採用されていないため、代わりに `NSWindow.setFrameAutosaveName(_:)`
   によるOS標準の位置・サイズ復元を使用しています。
10. **「システム設定を開く」ボタン（IF-006）**: `x-apple.systempreferences:` の
    URLスキームを使用しています。これはApple公式ドキュメントで保証された
    APIではなく、将来のOSアップデートで変更・廃止される可能性があります。

## テストについて

`Tests/ClockKitForMacTests/` に XCTest を一部実装しています（UT-SPEC-001 準拠のテストID
コメント付き）。

- `CalendarGridBuilderTests.swift` — UT-MOD008-01〜07（純粋関数のため依存なしでテスト可能）
- `AppSettingsTests.swift` — UT-MOD006-05〜11（`UserDefaults(suiteName:)` で本番設定と分離）
- `NextEventFetcherFormattingTests.swift` — UT-MOD009-07〜10（`formatEventTime` の文字列整形部分のみ）

UT-SPEC-001 は全75ケースを定義していますが、以下は本リポジトリには未実装です。実装する
場合は下記の対応が必要です。

- **ClockEngine（MOD-001, C++）**: UT-SPEC-001 は Google Test を使用する方針ですが、
  本リポジトリには Google Test のセットアップを含めていません。
- **CalendarViewModel（MOD-007）/ PermissionManager（MOD-010）/ NextEventFetcher.fetch(...)
  （MOD-009）**: UT-SPEC-001 のモック方針は `EKEventStore` を `MockEventStore` プロトコルで
  モック化する前提ですが、DD-001 の疑似コードはいずれも具体的な `EKEventStore` 型を
  直接受け取る設計になっています。DD-001 に忠実な実装を優先したため、本リポジトリでは
  プロトコル抽象化を行っていません。モックベースのテストを追加する場合は、これらの
  イニシャライザ引数をプロトコル型に変更するリファクタリングが前提になります。
- **IT-SPEC-001（結合テスト, 35ケース）**: 実機・実際の Calendar.app・スリープ/復帰・
  72時間連続稼働など、性質上 XCTest では自動化できないケースが大半のため、手動テスト
  手順書としてそのままご利用ください。

## ライセンス

社内プロジェクト想定のため未設定です。必要に応じて LICENSE ファイルを追加してください。
