//
//  POSRunLoopRunner.h
//  POSBlobInputStreamTests
//
//  Created by Pavel Osipov on 09.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <dispatch/dispatch.h>

typedef enum {
    POSRunLoopResultDone,
    POSRunLoopResultTimeout
} POSRunLoopResult;

@interface POSRunLoopRunner : NSObject

@property (nonatomic, copy) NSString *runLoopMode;

// Applicatble only for launchCFRunLoopWithStream selector
@property (nonatomic) CFOptionFlags streamEvents;
@property (nonatomic) BOOL removeClientWithNoneEvent;
@property (nonatomic) BOOL removeClientWithNullCallback;
@property (nonatomic) BOOL removeClientWithNullContext;
@property (nonatomic) BOOL shouldSubscribeAfterStreamOpen;

- (POSRunLoopResult)launchNSRunLoopWithStream:(NSInputStream *)stream
                                     delegate:(id<NSStreamDelegate>)streamDelegate;

- (POSRunLoopResult)launchCFRunLoopWithStream:(NSInputStream *)stream
                                     delegate:(id<NSStreamDelegate>)streamDelegate;

@end
