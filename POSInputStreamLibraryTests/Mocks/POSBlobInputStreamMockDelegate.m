//
//  POSBlobInputStreamMockDelegate.m
//  POSBlobInputStreamTests
//
//  Created by Pavel Osipov on 16.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamMockDelegate.h"

static NSString *streamStatusDescription(NSStreamStatus status) {
    switch (status) {
        case NSStreamStatusNotOpen: return @"NSStreamStatusNotOpen";
        case NSStreamStatusOpening: return @"NSStreamStatusOpening";
        case NSStreamStatusOpen:    return @"NSStreamStatusOpen";
        case NSStreamStatusReading: return @"NSStreamStatusReading";
        case NSStreamStatusWriting: return @"NSStreamStatusWriting";
        case NSStreamStatusAtEnd:   return @"NSStreamStatusAtEnd";
        case NSStreamStatusClosed:  return @"NSStreamStatusClosed";
        case NSStreamStatusError:   return @"NSStreamStatusError";
        default:                    return [NSString stringWithFormat:@"Unknown: %d", (int)status];
    }
}

static NSString *streamEventDescription(NSStreamEvent event) {
    switch (event) {
        case NSStreamEventNone:              return @"NSStreamEventNone";
        case NSStreamEventOpenCompleted:     return @"NSStreamEventOpenCompleted";
        case NSStreamEventHasBytesAvailable: return @"NSStreamEventHasBytesAvailable";
        case NSStreamEventHasSpaceAvailable: return @"NSStreamEventHasSpaceAvailable";
        case NSStreamEventErrorOccurred:     return @"NSStreamEventErrorOccurred";
        case NSStreamEventEndEncountered:    return @"NSStreamEventEndEncountered";
        default:                             return [NSString stringWithFormat:@"Unknown: %d", (int)event];
    }
}

@implementation POSBlobInputStreamMockDelegate {
    NSMutableDictionary *_invokeCountDictionary;
    NSMutableDictionary *_eventHandlers;
}

- (id)init {
    if (self = [super init]) {
        _invokeCountDictionary = [NSMutableDictionary dictionary];
        _eventHandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSNumber *)numberForEvent:(NSStreamEvent)event {
    NSNumber *key = [NSNumber numberWithInt:event];
    NSNumber *counter = [_invokeCountDictionary objectForKey:key];
    if (!counter) {
        counter = [NSNumber numberWithInt:0];
    }
    return counter;
}

- (NSNumber *)totalEventCount {
    __block int result = 0;
    [_invokeCountDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        result += [obj intValue];
    }];
    return [NSNumber numberWithInt:result];
}

- (void)handleEvent:(NSStreamEvent)event withBlock:(void (^)(NSStream *))eventHandler {
    _eventHandlers[@(event)] = eventHandler;
}

#pragma mark - Private

- (void)setNumber:(NSNumber *)number forEvent:(NSStreamEvent)event {
    [_invokeCountDictionary setObject:number forKey:[NSNumber numberWithInt:event]];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    NSLog(@"%@: Handling event=%@, streamStatus=%@...", [NSThread currentThread], streamEventDescription(eventCode), streamStatusDescription([aStream streamStatus]));
    [self setNumber:[NSNumber numberWithInt:[[self numberForEvent:eventCode] intValue] + 1] forEvent:eventCode];
	void (^eventHandler)(NSStream *) = _eventHandlers[@(eventCode)];
	if (eventHandler) {
        eventHandler(aStream);
	}
}

@end

