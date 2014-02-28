//
//  POSBlobInputStreamMockDelegate.h
//  POSBlobInputStreamTests
//
//  Created by Pavel Osipov on 16.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface POSBlobInputStreamMockDelegate : NSObject <NSStreamDelegate>

- (NSNumber *)numberForEvent:(NSStreamEvent)event;
- (NSNumber *)totalEventCount;

- (void)handleEvent:(NSStreamEvent)event withBlock:(void (^)(NSStream *))eventHandler;

@end
