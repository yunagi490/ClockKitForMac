//
//  ClockEngineBridge.mm
//  ClockKitForMac
//
//  ClockEngine.hpp (C++) を保持し、Objective-C ブロックで
//  Swift 側へコールバックを橋渡しする薄いラッパー。
//
#import "ClockEngineBridge.h"
#import "ClockEngine.hpp"

#include <memory>

@interface ClockEngineBridge () {
    std::unique_ptr<ClockEngine> _engine;
}
@end

@implementation ClockEngineBridge

- (instancetype)init {
    self = [super init];
    if (self) {
        _engine = std::make_unique<ClockEngine>();
    }
    return self;
}

- (void)startWithIntervalNs:(int64_t)intervalNs
                    handler:(ClockEngineTickHandler)handler {
    if (!_engine) {
        return;
    }

    ClockEngineTickHandler handlerCopy = [handler copy];
    ClockEngine::Callback callback = [handlerCopy](int64_t timestampNs) {
        if (handlerCopy) {
            handlerCopy(timestampNs);
        }
    };

    if (intervalNs > 0) {
        _engine->start(std::move(callback), intervalNs);
    } else {
        _engine->start(std::move(callback));
    }
}

- (void)stop {
    if (_engine) {
        _engine->stop();
    }
}

- (void)suspendTimer {
    if (_engine) {
        _engine->suspend();
    }
}

- (void)resumeTimer {
    if (_engine) {
        _engine->resume();
    }
}

@end
