//
//  ClockEngine.hpp
//  ClockKitForMac
//
//  MOD-001: DispatchSourceTimer を用いた高精度タイマー。
//  clock_gettime() でナノ秒精度の時刻を取得し、1秒ごとに
//  コールバックを発火する。関連: FRQ-001, FRQ-002 / DD-001 MOD-001
//
#pragma once

#include <cstdint>
#include <functional>
#include <dispatch/dispatch.h>

/// システムクロックから時刻を取得し、GCD の DispatchSourceTimer で
/// 一定間隔ごとにコールバックを発火する C++ 層のタイマーエンジン。
///
/// スレッドセーフティ: start/stop/suspend/resume はすべて同一の
/// シリアルキュー上で実行されることを前提とする（呼び出し元の
/// ClockEngineBridge がメインスレッドからのみ呼び出す）。
class ClockEngine {
public:
    using Callback = std::function<void(int64_t)>;

    ClockEngine();
    ~ClockEngine();

    // コピー・ムーブ禁止（dispatch_source_t を保持するため）
    ClockEngine(const ClockEngine&) = delete;
    ClockEngine& operator=(const ClockEngine&) = delete;

    /// タイマーを開始する。既に起動中の場合は二重起動防止のため
    /// 何もせず即座に返る。
    /// @param callback 1秒（既定）ごとに呼び出すコールバック。
    ///                 引数は clock_gettime() 由来の Unix タイムスタンプ(ナノ秒)。
    /// @param intervalNs タイマー間隔（ナノ秒）。省略時は 1,000,000,000ns(=1秒)。
    void start(Callback callback, int64_t intervalNs = 1'000'000'000LL);

    /// タイマーを停止しリソースを解放する。
    void stop();

    /// タイマーを一時停止する（バックグラウンド移行時のCPU節約用）。
    /// 既に停止中・一時停止中の場合は安全に無視される。
    void suspend();

    /// 一時停止したタイマーを再開する。
    /// stop() 済み、または既に稼働中の場合は安全に無視される。
    void resume();

private:
    /// clock_gettime(CLOCK_REALTIME) でナノ秒精度の現在時刻を取得する。
    /// ENOSYS 等で失敗した場合は gettimeofday() にフォールバックする。
    int64_t currentTimeNs() const;

    void fireCallback();

    dispatch_source_t timer_ = nullptr;
    Callback callback_;
    bool isRunning_ = false;
};
