//
//  PermissionStatus.swift
//  ClockKitForMac
//
//  EventKit 権限状態。DD-001 MOD-010(PermissionManager) に対応する。
//
import Foundation

enum PermissionStatus: Equatable {
    /// 未確認（初回起動）
    case notDetermined
    /// 許可済み
    case granted
    /// ユーザーが拒否
    case denied
    /// MDM 等のポリシーで制限
    case restricted
}
