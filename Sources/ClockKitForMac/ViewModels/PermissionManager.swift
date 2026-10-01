//
//  PermissionManager.swift
//  ClockKitForMac
//
//  MOD-010: EKEventStore 権限の確認・リクエストを Swift actor で
//  非同期・スレッドセーフに管理する。DD-001 MOD-010 に準拠。
//  関連: FRQ-011, FRQ-015
//
import EventKit
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "PermissionManager")

actor PermissionManager {
    private let store: EKEventStore

    init(store: EKEventStore) {
        self.store = store
    }

    /// 現在の権限状態を返す。
    func checkStatus() -> PermissionStatus {
        let raw = EKEventStore.authorizationStatus(for: .event)
        return Self.map(raw)
    }

    /// 権限リクエストを行い結果を返す。
    /// macOS 14+ では requestFullAccessToEvents()、それ以前では
    /// requestAccess(to:) を使用する。
    func requestAccess() async -> PermissionStatus {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }

            if granted {
                logger.info("Calendar access granted")
                return .granted
            } else {
                logger.info("Calendar access denied by user")
                return .denied
            }
        } catch {
            logger.error("requestAccess threw: \(error.localizedDescription, privacy: .public)")
            return .denied
        }
    }

    /// フォールバック（予定表示の抑制）が必要かどうかを返す（FRQ-015）。
    func shouldFallback(status: PermissionStatus) -> Bool {
        switch status {
        case .granted:
            return false
        case .notDetermined:
            // リクエスト前は待機（まだフォールバックしない）
            return false
        case .denied, .restricted:
            return true
        }
    }

    /// EKAuthorizationStatus を PermissionStatus にマップする。
    /// macOS14+ の fullAccess は .granted に、未知のケースは
    /// .notDetermined にフォールバックする（将来の OS 更新対応）。
    private static func map(_ raw: EKAuthorizationStatus) -> PermissionStatus {
        switch raw {
        case .fullAccess:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        case .writeOnly:
            // 本アプリは読取専用のみ使用するため writeOnly は未許可として扱う。
            return .denied
        case .authorized:
            // 旧 OS 系の "authorized" を granted にマップ。
            return .granted
        @unknown default:
            logger.warning("Unknown EKAuthorizationStatus: \(String(describing: raw), privacy: .public)")
            return .notDetermined
        }
    }
}
