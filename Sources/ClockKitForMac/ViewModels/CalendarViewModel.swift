//
//  CalendarViewModel.swift
//  ClockKitForMac
//
//  MOD-007: EventKit連携の中核クラス。権限管理・カレンダー一覧取得・
//  予定ドット生成・次の予定取得を統括する。DD-001 MOD-007 に準拠。
//  関連: FRQ-011〜015
//
import EventKit
import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "CalendarViewModel")

@MainActor
final class CalendarViewModel: ObservableObject {

    // MARK: - Published プロパティ（View が bind する）

    /// 当月の日付配列（42要素）。各要素に hasEvent フラグを持つ。
    @Published private(set) var calendarDays: [CalendarDay] = []
    /// 次の予定。nil = 予定なし。
    @Published private(set) var nextEvent: NextEventInfo?
    /// 設定画面用カレンダー一覧。
    @Published private(set) var availableCalendars: [EKCalendar] = []
    /// true = 権限なし。View 層が予定表示を非表示にする（FRQ-015）。
    @Published private(set) var fallbackMode: Bool = false
    /// カレンダーグリッドの表示月（year/month）。
    @Published private(set) var displayMonth: DateComponents

    /// 権限が .restricted（MDM等）かどうか。設定画面の案内文分岐に使用。
    @Published private(set) var isRestricted: Bool = false

    let store: EKEventStore
    private let settings: SettingsStore
    private let permissionManager: PermissionManager
    private var cancellables: Set<AnyCancellable> = []
    private var changeObserver: NSObjectProtocol?
    private var autoRefreshTimer: Timer?

    init(settings: SettingsStore, store: EKEventStore = EKEventStore()) {
        self.settings = settings
        self.store = store
        self.permissionManager = PermissionManager(store: store)
        self.displayMonth = Calendar.current.dateComponents([.year, .month], from: Date())

        // カレンダー選択・先読み時間の変更を監視し、即時再取得する。
        settings.$current
            .map { ($0.selectedCalendarIDs, $0.eventLookaheadHours) }
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .dropFirst()
            .sink { [weak self] _ in
                Task { await self?.refreshEvents() }
            }
            .store(in: &cancellables)
    }

    deinit {
        if let token = changeObserver {
            NotificationCenter.default.removeObserver(token)
        }
        autoRefreshTimer?.invalidate()
    }

    // MARK: - 起動時初期化（FRQ-011）

    /// 起動時に権限を確認し、許可済みならカレンダー・予定を読み込む。
    /// 未確認の場合はこの関数では権限リクエストを行わない
    /// （オンボーディングの requestCalendarAccess() が明示的に行う）。
    func initialize() async {
        let status = await permissionManager.checkStatus()
        await applyPermissionStatus(status)
        observeStoreChanges()
        startAutoRefreshTimer()
    }

    /// オンボーディング（SCR-004）から明示的に権限をリクエストする。
    @discardableResult
    func requestCalendarAccess() async -> PermissionStatus {
        let status = await permissionManager.requestAccess()
        await applyPermissionStatus(status)
        return status
    }

    private func applyPermissionStatus(_ status: PermissionStatus) async {
        isRestricted = (status == .restricted)
        let shouldFallback = await permissionManager.shouldFallback(status: status)
        fallbackMode = shouldFallback

        if status == .granted {
            await loadCalendars()
            await refreshEvents()
        }
    }

    // MARK: - カレンダー一覧取得（FRQ-012）

    func loadCalendars() async {
        let all = store.calendars(for: .event)
        availableCalendars = all

        let validIDs = Set(all.map { $0.calendarIdentifier })
        let saved = Set(settings.current.selectedCalendarIDs)

        if saved.isEmpty {
            // 初回: 全カレンダーを選択
            settings.update { $0.selectedCalendarIDs = all.map { $0.calendarIdentifier } }
        } else {
            let intersected = Array(saved.intersection(validIDs))
            if intersected.isEmpty && !validIDs.isEmpty {
                // 全て削除済みだった場合は自動修復（全選択に戻す）
                logger.warning("All selected calendars were deleted, resetting")
                settings.update { $0.selectedCalendarIDs = Array(validIDs) }
            } else if Set(intersected) != saved {
                settings.update { $0.selectedCalendarIDs = intersected }
            }
        }
    }

    // MARK: - グリッド・次の予定の再取得（FRQ-013, FRQ-014）

    func refreshEvents() async {
        guard !fallbackMode else { return }

        let selectedIDs = Set(settings.current.selectedCalendarIDs)
        let calendars = availableCalendars.filter { selectedIDs.contains($0.calendarIdentifier) }

        guard !calendars.isEmpty else {
            nextEvent = nil
            calendarDays = CalendarGridBuilder.build(month: displayMonth, eventDates: [])
            return
        }

        guard let (monthStart, monthEnd) = monthBounds(of: displayMonth) else {
            logger.error("refreshEvents: invalid displayMonth")
            return
        }

        var eventDates = Set<Int>()
        let predicate = store.predicateForEvents(startDate: monthStart, endDate: monthEnd, calendars: calendars)
        store.enumerateEvents(matching: predicate) { event, _ in
            let day = Calendar.current.component(.day, from: event.startDate)
            eventDates.insert(day)
        }

        calendarDays = CalendarGridBuilder.build(month: displayMonth, eventDates: eventDates)

        nextEvent = NextEventFetcher.fetch(
            store: store,
            calendars: calendars,
            from: Date(),
            lookaheadHours: settings.current.eventLookaheadHours
        )
    }

    // MARK: - 月ナビゲーション（SCR-001 ⑦、±24ヶ月制限）

    func navigateMonth(offset: Int) {
        let cal = Calendar.current
        guard let currentDate = cal.date(from: displayMonth),
              let newDate = cal.date(byAdding: .month, value: offset, to: currentDate) else {
            return
        }

        let newComponents = cal.dateComponents([.year, .month], from: newDate)

        let thisMonth = cal.dateComponents([.year, .month], from: Date())
        guard let diff = monthDiff(from: thisMonth, to: newComponents), abs(diff) <= 24 else {
            logger.debug("Month navigation out of range")
            return
        }

        displayMonth = newComponents
        Task { await refreshEvents() }
    }

    /// 現在月から見た月差の絶対値が24を超えているかどうか（ナビボタンの
    /// グレーアウト判定に使用）。
    func isNavigationOutOfRange(offset: Int) -> Bool {
        let cal = Calendar.current
        guard let currentDate = cal.date(from: displayMonth),
              let candidateDate = cal.date(byAdding: .month, value: offset, to: currentDate) else {
            return true
        }
        let candidate = cal.dateComponents([.year, .month], from: candidateDate)
        let thisMonth = cal.dateComponents([.year, .month], from: Date())
        guard let diff = monthDiff(from: thisMonth, to: candidate) else { return true }
        return abs(diff) > 24
    }

    // MARK: - カレンダー選択操作（設定画面用）

    func setCalendar(_ calendar: EKCalendar, selected: Bool) {
        settings.update { s in
            var ids = Set(s.selectedCalendarIDs)
            if selected {
                ids.insert(calendar.calendarIdentifier)
            } else {
                ids.remove(calendar.calendarIdentifier)
            }
            s.selectedCalendarIDs = Array(ids)
        }
    }

    func deselectAllCalendars() {
        settings.update { $0.selectedCalendarIDs = [] }
    }

    // MARK: - 外部変更監視（IF-005）

    private func observeStoreChanges() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { await self?.refreshEvents() }
        }
    }

    /// 60秒ごとの自動更新（IF-SPEC-001 IF-002: 起動時・60秒ごと・変更通知時）。
    private func startAutoRefreshTimer() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshEvents()
            }
        }
    }

    // MARK: - 日付計算ヘルパー

    private func monthBounds(of components: DateComponents) -> (start: Date, end: Date)? {
        let cal = Calendar.current
        guard let start = cal.date(from: components),
              let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) else {
            return nil
        }
        let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
        return (start, endOfDay)
    }

    private func monthDiff(from a: DateComponents, to b: DateComponents) -> Int? {
        guard let ay = a.year, let am = a.month, let by = b.year, let bm = b.month else { return nil }
        return (by - ay) * 12 + (bm - am)
    }
}
