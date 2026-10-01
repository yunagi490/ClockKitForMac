//
//  ClockEngine.cpp
//  ClockKitForMac
//
//  MOD-001 実装。DD-001 / IF-SPEC-001(IF-001) の疑似コードに準拠。
//
#include "ClockEngine.hpp"

#include <ctime>
#include <sys/time.h>
#include <os/log.h>

namespace {
os_log_t clockEngineLog() {
    static os_log_t log = os_log_create("com.clockkit.formac", "ClockEngine");
    return log;
}
}  // namespace

ClockEngine::ClockEngine() = default;

ClockEngine::~ClockEngine() {
    stop();
}

void ClockEngine::start(Callback callback, int64_t intervalNs) {
    // 二重起動防止（UT-MOD001-02）
    if (timer_ != nullptr) {
        os_log_info(clockEngineLog(), "ClockEngine already running, start() ignored");
        return;
    }

    callback_ = std::move(callback);

    dispatch_queue_t serialQueue = dispatch_queue_create(
        "com.clockkit.formac.ClockEngine", DISPATCH_QUEUE_SERIAL);

    timer_ = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, serialQueue);

    if (timer_ == nullptr) {
        os_log_fault(clockEngineLog(), "Failed to create DispatchSourceTimer");
        return;
    }

    dispatch_source_set_timer(
        timer_,
        dispatch_time(DISPATCH_TIME_NOW, 0),
        static_cast<uint64_t>(intervalNs),
        /* leeway */ 0);

    dispatch_source_set_event_handler(timer_, ^{
        this->fireCallback();
    });

    dispatch_resume(timer_);
    isRunning_ = true;
}

void ClockEngine::stop() {
    if (timer_ == nullptr) {
        return;
    }

    // suspend 中の cancel はクラッシュするため、必ず resume してから cancel する。
    if (!isRunning_) {
        dispatch_resume(timer_);
        isRunning_ = true;
    }

    dispatch_source_cancel(timer_);
    timer_ = nullptr;
    isRunning_ = false;
    callback_ = nullptr;
}

void ClockEngine::suspend() {
    // ERR-002 (double_suspend) 防止: 既に停止中なら何もしない。
    if (timer_ != nullptr && isRunning_) {
        dispatch_suspend(timer_);
        isRunning_ = false;
    }
}

void ClockEngine::resume() {
    if (timer_ != nullptr && !isRunning_) {
        dispatch_resume(timer_);
        isRunning_ = true;
    }
}

int64_t ClockEngine::currentTimeNs() const {
    struct timespec ts;
    int ret = clock_gettime(CLOCK_REALTIME, &ts);

    if (ret != 0) {
        // フォールバック: gettimeofday()（精度はマイクロ秒に劣化）
        os_log_error(clockEngineLog(),
                      "clock_gettime failed, fallback to gettimeofday");
        struct timeval tv;
        gettimeofday(&tv, nullptr);
        return static_cast<int64_t>(tv.tv_sec) * 1'000'000'000LL +
               static_cast<int64_t>(tv.tv_usec) * 1'000LL;
    }

    // 異常値チェック（tv_nsec が範囲外）
    if (ts.tv_nsec < 0 || ts.tv_nsec > 999'999'999) {
        os_log_error(clockEngineLog(), "Abnormal tv_nsec value detected");
    }

    return static_cast<int64_t>(ts.tv_sec) * 1'000'000'000LL +
           static_cast<int64_t>(ts.tv_nsec);
}

void ClockEngine::fireCallback() {
    if (!callback_) {
        return;
    }
    const int64_t ns = currentTimeNs();
    callback_(ns);
}
