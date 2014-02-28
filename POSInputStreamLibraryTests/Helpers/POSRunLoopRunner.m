//
//  POSRunLoopRunner.m
//  POSBlobInputStreamTests
//
//  Created by Pavel Osipov on 09.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import "POSRunLoopRunner.h"

static const NSTimeInterval kRunLoopCycleInterval = 0.01f;
static const uint64_t kDispatchDeltaNanoSec = 250000000;

static void CFRunLoopPerformCallBack(CFReadStreamRef stream, CFStreamEventType type, void *context) {
    id<NSStreamDelegate> delegate = (__bridge id<NSStreamDelegate>)context;
	[delegate stream:(__bridge NSInputStream *)stream handleEvent:(NSStreamEvent)type];
}

@implementation POSRunLoopRunner : NSObject

- (id)init {
    if (self = [super init]) {
        _streamEvents = (kCFStreamEventOpenCompleted |
                         kCFStreamEventHasBytesAvailable |
                         kCFStreamEventEndEncountered |
                         kCFStreamEventErrorOccurred);
        _removeClientWithNoneEvent = NO;
        _removeClientWithNullCallback = NO;
        _removeClientWithNullContext = NO;
        _shouldSubscribeAfterStreamOpen = NO;
    }
    return self;
}

- (POSRunLoopResult)launchNSRunLoopWithStream:(NSInputStream *)stream delegate:(id<NSStreamDelegate>)streamDelegate {
    if (!_shouldSubscribeAfterStreamOpen) {
        stream.delegate = streamDelegate;
    }
    __block BOOL breakRunLoop = NO;
    __block dispatch_semaphore_t doneSemaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *runLoopMode = _runLoopMode == nil ? NSDefaultRunLoopMode : _runLoopMode;
        NSLog(@"%@: scheduling stream...", [NSThread currentThread]);
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [stream scheduleInRunLoop:runLoop forMode:runLoopMode];
        if ([stream streamStatus] == NSStreamStatusNotOpen) {
            NSLog(@"%@: opening stream...", [NSThread currentThread]);
            [stream open];
        }
        while ([runLoop runMode:runLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:kRunLoopCycleInterval]] && !breakRunLoop) {
            if (stream.delegate != streamDelegate) {
                NSLog(@"%@: subscribing...", [NSThread currentThread]);
                stream.delegate = streamDelegate;
            }
        }
        NSLog(@"%@: We are done!", [NSThread currentThread]);
        dispatch_semaphore_signal(doneSemaphore);
    });
    POSRunLoopResult result = dispatch_semaphore_wait(doneSemaphore, dispatch_time(DISPATCH_TIME_NOW, kDispatchDeltaNanoSec)) == 0 ? POSRunLoopResultDone : POSRunLoopResultTimeout;
    if (POSRunLoopResultTimeout == result) {
        breakRunLoop = YES;
        dispatch_semaphore_wait(doneSemaphore, DISPATCH_TIME_FOREVER);
    }
    return result;
}

- (POSRunLoopResult)launchCFRunLoopWithStream:(NSInputStream *)stream delegate:(id<NSStreamDelegate>)streamDelegate {
    __block BOOL breakRunLoop = NO;
    __block dispatch_semaphore_t doneSemaphore = dispatch_semaphore_create(0);
    __weak typeof(self) this = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFStringRef runLoopMode = _runLoopMode == nil ? kCFRunLoopDefaultMode : (__bridge CFStringRef)_runLoopMode;
        CFReadStreamRef readStream = (__bridge CFReadStreamRef)stream;
        CFStreamClientContext context = {0, (__bridge void *)(streamDelegate), NULL, NULL, NULL};
        NSLog(@"%@: scheduling stream...", [NSThread currentThread]);
        Boolean result = CFReadStreamSetClient(readStream, this.streamEvents, CFRunLoopPerformCallBack, &context);
        NSParameterAssert(result);
        if (this.removeClientWithNoneEvent) {
            result = CFReadStreamSetClient(readStream, kCFStreamEventNone, CFRunLoopPerformCallBack, &context);
        } else if (this.removeClientWithNullCallback) {
            result = CFReadStreamSetClient(readStream, this.streamEvents, NULL, &context);
        } else if (this.removeClientWithNullContext) {
            result = CFReadStreamSetClient(readStream, this.streamEvents, CFRunLoopPerformCallBack, NULL);
        }
        NSParameterAssert(result);
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), runLoopMode);
        if (CFReadStreamGetStatus(readStream) == kCFStreamStatusNotOpen) {
            NSLog(@"%@: opening stream...", [NSThread currentThread]);
            result = CFReadStreamOpen(readStream);
            NSParameterAssert(result);
        }
        for (;;) {
            const SInt32 r = CFRunLoopRunInMode(runLoopMode, kRunLoopCycleInterval, true);
            if (r == kCFRunLoopRunStopped || r == kCFRunLoopRunFinished || breakRunLoop) {
                break;
            }
        }
        NSLog(@"%@: We are done!", [NSThread currentThread]);
        dispatch_semaphore_signal(doneSemaphore);
    });
    POSRunLoopResult result = dispatch_semaphore_wait(doneSemaphore, dispatch_time(DISPATCH_TIME_NOW, kDispatchDeltaNanoSec)) == 0 ? POSRunLoopResultDone : POSRunLoopResultTimeout;
    if (POSRunLoopResultTimeout == result) {
        breakRunLoop = YES;
        dispatch_semaphore_wait(doneSemaphore, DISPATCH_TIME_FOREVER);
    }
    return result;
}

@end
