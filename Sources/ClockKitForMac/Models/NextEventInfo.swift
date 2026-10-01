//
//  NextEventInfo.swift
//  ClockKitForMac
//
//  「次の予定」エリアに表示するイベント情報。
//  DD-001 MOD-009(NextEventFetcher) が生成する。関連: FRQ-014
//
import SwiftUI

struct NextEventInfo: Equatable {
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let calendarColor: Color
    let calendarTitle: String
}
