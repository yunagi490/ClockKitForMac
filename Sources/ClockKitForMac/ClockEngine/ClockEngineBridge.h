//
//  ClockEngineBridge.h
//  ClockKitForMac
//
//  C++ の ClockEngine を Swift から安全に利用するための
//  Objective-C ブリッジ（API-001〜API-004 に対応）。
//  Swift 側は Bridging Header 経由でこのクラスのみを参照し、
//  C++ ヘッダーを直接 import しない。
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 1秒（既定）ごとに呼び出されるコールバック。
/// 引数は Unix タイムスタンプ（ナノ秒）。
/// GCD のシリアルキュー上から呼ばれるため、UI 更新は
/// 呼び出し側で必ず DispatchQueue.main.async に移譲すること。
typedef void (^ClockEngineTickHandler)(int64_t timestampNs);

@interface ClockEngineBridge : NSObject

/// タイマーを開始する（API-001）。二重起動は内部で無視される。
/// @param intervalNs タイマー間隔（ナノ秒）。0 を渡すと既定値(1秒)が使われる。
- (void)startWithIntervalNs:(int64_t)intervalNs
                    handler:(ClockEngineTickHandler)handler;

/// タイマーを停止しリソースを解放する（API-002）。
- (void)stop;

/// タイマーを一時停止する（API-003 / バックグラウンド移行時）。
- (void)suspendTimer;

/// 一時停止したタイマーを再開する（API-004 / フォアグラウンド復帰時）。
- (void)resumeTimer;

@end

NS_ASSUME_NONNULL_END
