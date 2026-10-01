//
//  CalendarSettingsTab.swift
//  ClockKitForMac
//
//  項目定義 ⑯(カレンダー表示/非表示) ＋ カレンダー選択チェックリスト・
//  先読み時間設定・EventKit権限警告バナー（IT-SN007, IT-SN015 準拠）。
//  「システム設定を開く」ボタンは IF-SPEC-001（IF-006）に基づき実装。
//
import SwiftUI
import AppKit
import EventKit

struct CalendarSettingsTab: View {
    @EnvironmentObject private var env: AppEnvironment

    private var calendar: CalendarViewModel { env.calendarViewModel }

    private static let lookaheadOptions: [(hours: Int, label: String)] = [
        (24, "24時間以内"),
        (72, "3日以内"),
        (168, "7日以内"),
    ]

    var body: some View {
        Form {
            if calendar.fallbackMode {
                Section {
                    permissionWarningBanner
                }
            }

            Section("表示") {
                // ⑯ カレンダー表示/非表示（ラジオボタン）
                Picker("", selection: calendarVisibleBinding) {
                    Text("カレンダーを表示する").tag(true)
                    Text("カレンダーを非表示にする（時計のみ表示）").tag(false)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            if !calendar.fallbackMode {
                Section("対象カレンダー") {
                    if calendar.availableCalendars.isEmpty {
                        Text("カレンダーが見つかりません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(calendar.availableCalendars, id: \.calendarIdentifier) { cal in
                            Toggle(isOn: calendarSelectionBinding(for: cal)) {
                                Label {
                                    Text(cal.title)
                                } icon: {
                                    Circle()
                                        .fill(Color(cgColor: cal.cgColor))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }

                        Button("すべて解除") {
                            calendar.deselectAllCalendars()
                        }
                        .buttonStyle(.link)
                    }
                }

                Section("先読み時間") {
                    Picker("次の予定の検索範囲", selection: lookaheadBinding) {
                        ForEach(Self.lookaheadOptions, id: \.hours) { option in
                            Text(option.label).tag(option.hours)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private var permissionWarningBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                calendar.isRestricted
                    ? "ポリシーによりカレンダーへのアクセスが制限されています"
                    : "カレンダーへのアクセスが許可されていません",
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            if !calendar.isRestricted {
                Button("システム設定を開く") {
                    openCalendarPrivacySettings()
                }
            }
        }
    }

    /// macOS のプライバシー設定（カレンダー）をURLスキームで開く（IF-006）。
    private func openCalendarPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    private var calendarVisibleBinding: Binding<Bool> {
        Binding(
            get: { env.settings.current.calendarVisible },
            set: { newValue in env.settings.update { $0.calendarVisible = newValue } }
        )
    }

    private var lookaheadBinding: Binding<Int> {
        Binding(
            get: { env.settings.current.eventLookaheadHours },
            set: { newValue in env.settings.update { $0.eventLookaheadHours = newValue } }
        )
    }

    private func calendarSelectionBinding(for cal: EKCalendar) -> Binding<Bool> {
        Binding(
            get: { env.settings.current.selectedCalendarIDs.contains(cal.calendarIdentifier) },
            set: { newValue in calendar.setCalendar(cal, selected: newValue) }
        )
    }
}
