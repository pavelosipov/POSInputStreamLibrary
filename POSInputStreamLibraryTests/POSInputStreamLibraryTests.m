//
//  POSBlobInputStreamLibraryTests.m
//  POSBlobInputStreamLibraryTests
//
//  Created by Pavel Osipov on 17.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import "POSInputStreamLibraryTests.h"

#import "POSBlobInputStream.h"
#import "POSBlobInputStreamMockDataSource.h"
#import "POSBlobInputStreamMockDelegate.h"
#import "POSRunLoopRunner.h"

@implementation POSBlobInputStreamLibraryTests {
    NSInputStream *_blobStream;
    POSBlobInputStreamMockDelegate *_streamDelegate;
    POSRunLoopRunner *_runLoopRunner;
}

- (void)setUp {
    [super setUp];
    POSBlobInputStream *blobStream = [[POSBlobInputStream alloc] initWithDataSource:[[POSBlobInputStreamMockDataSource alloc] initWithLength:9]];
    blobStream.shouldNotifyCoreFoundationAboutStatusChange = YES;
    _blobStream = blobStream;
    _streamDelegate = [[POSBlobInputStreamMockDelegate alloc] init];
    _runLoopRunner = [[POSRunLoopRunner alloc] init];
}

- (void)tearDown {
    _streamDelegate = nil;
    _blobStream = nil;
    _runLoopRunner = nil;
    [super tearDown];
}

- (void)testStreamMayBeInCloseStateOnlyAfterOpening {
    [_blobStream close];
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusNotOpen, @"Close should do nothing before open.");
    [_blobStream open];
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusOpen, @"It is ok to open stream after close attempt.");
    [_blobStream close];
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"It should be possible to close opened stream.");
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"It should be possible to launch NSRunLoop with closed stream.");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @0, @"No events should be emitted via closed stream.");
}

- (void)testNSRunLoopShouldBeRunningWhileStreamIsOpen {
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"NSRunLoop should be running infinitely because we don't close stream.");
    XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @1, @"Should be 1 HasBytesAvailable event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testCFRunLoopShouldBeRunningWhileStreamIsOpen {
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"CFRunLoop should be running infinitely because we don't close stream.");
    XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @1, @"Should be 1 HasBytesAvailable event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testNSRunLoopShouldBeRunningWhileStreamIsOpenAndEmpty {
    NSInputStream *emptyStream = [[POSBlobInputStream alloc] initWithDataSource:[[POSBlobInputStreamMockDataSource alloc] init]];
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:emptyStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"NSRunLoop should be running infinitely because we don't close stream.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
    XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventEndEncountered], @1, @"Should be 1 EndEncountered event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testCFRunLoopShouldBeRunningWhileStreamIsOpenAndEmpty {
    POSBlobInputStream *emptyStream = [[POSBlobInputStream alloc] initWithDataSource:[[POSBlobInputStreamMockDataSource alloc] init]];
    emptyStream.shouldNotifyCoreFoundationAboutStatusChange = YES;
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:emptyStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"CFRunLoop should be running infinitely because we don't close stream.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
    XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventEndEncountered], @1, @"Should be 1 EndEncountered event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testExitFromNSRunLoopWhenStreamIsClosed {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"NSRunLoop should be done after closing stream.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"Ensure stream is closed.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @1, @"Should be 1 HasBytesAvailable event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testExitFromCFRunLoopWhenStreamIsClosed {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"CFRunLoop should be done after closing stream.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"Ensure stream is closed.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @1, @"Should be 1 HasBytesAvailable event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testExitFromNSRunLoopWhenStreamIsClosedAndSheduledWithCustomMode {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _runLoopRunner.runLoopMode = @"CustomRunLoopMode";
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"NSRunLoop should be done after closing stream.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"Ensure stream is closed.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @1, @"Should be 1 HasBytesAvailable event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testExitFromCFRunLoopWhenStreamIsClosedAndSheduledWithCustomMode {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _runLoopRunner.runLoopMode = @"CustomRunLoopMode";
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"CFRunLoop should be done after closing stream.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"Ensure stream is closed.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @1, @"Should be 1 HasBytesAvailable event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @2, @"No other events should be emitted.");
}

- (void)testNotificationOptionsMaskForCFRunLoop {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _runLoopRunner.streamEvents = NSStreamEventHasBytesAvailable;
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"CFRunLoop should be done after closing stream.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"Ensure stream is closed.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @0, @"OpenCompleted event should be filtered");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @1, @"Should be 1 HasBytesAvailable event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @1, @"No other events should be emitted.");
}

- (void)testClientRemovingWithNoneEvent {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _runLoopRunner.removeClientWithNoneEvent = YES;
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"Because delegate has been removed from the stream nobody can close it, so CFRunLoop should be running.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusOpen, @"Ensure stream is open.");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @0, @"No events should be received because delegate has been removed.");
    [_blobStream close];
}

- (void)testClientRemovingWithNullCallback {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _runLoopRunner.removeClientWithNullCallback = YES;
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"Because delegate has been removed from the stream nobody can close it, so CFRunLoop should be running.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusOpen, @"Ensure stream is open.");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @0, @"No events should be received because delegate has been removed.");
    [_blobStream close];
}

- (void)testClientRemovingWithNullContext {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _runLoopRunner.removeClientWithNullContext = YES;
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"Because delegate has been removed from the stream nobody can close it, so CFRunLoop should be running.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusOpen, @"Ensure stream is open.");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @0, @"No events should be received because delegate has been removed.");
    [_blobStream close];
}

- (void)testStreamDelegateShouldNotReceiveEventsWithoutRunLoopScheduling {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _blobStream.delegate = _streamDelegate;
    [_blobStream open];
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusOpen, @"Ensure stream is open.");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @0, @"No events should be received because stream has not been scheduled.");
    [_blobStream close];
}

- (void)testStreamShouldSkipAllPendingEventsIfDelegateIsNotAvailable {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) { [stream close]; }];
    _runLoopRunner.shouldSubscribeAfterStreamOpen = YES;
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"NSRunLoop should be done after closing stream.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusOpen, @"Ensure stream is closed.");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @0, @"All events should be skipped.");
}

- (void)testStreamScheduledInNSRunLoopShouldBeInErrorStateAndEmitFailureEventIfOpenFailed {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"ALAssetRepresentation is unavailable." };
    NSError *openError = [NSError errorWithDomain:@"Bla" code:777 userInfo:userInfo];
    POSBlobInputStreamMockDataSource *dataSource = [[POSBlobInputStreamMockDataSource alloc] initWithOpenError:openError];
    POSBlobInputStream *failureStream = [[POSBlobInputStream alloc] initWithDataSource:dataSource];
    failureStream.shouldNotifyCoreFoundationAboutStatusChange = YES;
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:failureStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"Stream should be scheduled.");
    XCTAssertTrue([failureStream streamStatus] == NSStreamStatusError, @"Ensure stream is in error state.");
    XCTAssertEqualObjects([[failureStream streamError] domain], POSBlobInputStreamErrorDomain, @"Stream error should be with specified domain.");
    XCTAssertTrue([[failureStream streamError] code] == POSBlobInputStreamErrorCodeDataSourceFailure, @"Stream error should be with open error code.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @0, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventErrorOccurred], @1, @"Should be 1 ErrorOccurred event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @1, @"No other events should be emitted.");
}

- (void)testStreamScheduledInCFRunLoopShouldBeInErrorStateAndEmitFailureEventIfOpenFailed {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"ALAssetRepresentation is unavailable." };
    NSError *openError = [NSError errorWithDomain:@"Bla" code:777 userInfo:userInfo];
    POSBlobInputStreamMockDataSource *dataSource = [[POSBlobInputStreamMockDataSource alloc] initWithOpenError:openError];
    POSBlobInputStream *failureStream = [[POSBlobInputStream alloc] initWithDataSource:dataSource];
    failureStream.shouldNotifyCoreFoundationAboutStatusChange = YES;
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:failureStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultTimeout, @"Stream should be scheduled.");
    XCTAssertTrue([failureStream streamStatus] == NSStreamStatusError, @"Ensure stream is in error state.");
    XCTAssertEqualObjects([[failureStream streamError] domain], POSBlobInputStreamErrorDomain, @"Stream error should be with specified domain.");
    XCTAssertTrue([[failureStream streamError] code] == POSBlobInputStreamErrorCodeDataSourceFailure, @"Stream error should be with open error code.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @0, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventErrorOccurred], @1, @"Should be 1 ErrorOccurred event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @1, @"No other events should be emitted.");
}

- (void)testCFStreamShouldSendHaveAvailableBytesAfterEachReadCall {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) {
        uint8_t byte;
        [(NSInputStream *)stream read:&byte maxLength:1];
    }];
    [_streamDelegate handleEvent:NSStreamEventEndEncountered withBlock:^(NSStream *stream) {
        [stream close];
    }];
    POSRunLoopResult loopResult = [_runLoopRunner launchCFRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"Stream will be closed when empty.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"Ensure stream is in close state.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @9, @"Should be 9 HasBytesAvailable events: one after each read.");
    XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventEndEncountered], @1, @"Should be 1 EndEncountered event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @11, @"No other events should be emitted.");
}

- (void)testNSStreamShouldSendHaveAvailableBytesAfterEachReadCall {
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) {
        uint8_t byte;
        [(NSInputStream *)stream read:&byte maxLength:1];
    }];
    [_streamDelegate handleEvent:NSStreamEventEndEncountered withBlock:^(NSStream *stream) {
        [stream close];
    }];
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"Stream will be closed when empty.");
    XCTAssertTrue([_blobStream streamStatus] == NSStreamStatusClosed, @"Ensure stream is in close state.");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventOpenCompleted], @1, @"Should be 1 OpenCompleted event");
	XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventHasBytesAvailable], @9, @"Should be 9 HasBytesAvailable events: one after each read.");
    XCTAssertEqualObjects([_streamDelegate numberForEvent:NSStreamEventEndEncountered], @1, @"Should be 1 EndEncountered event");
    XCTAssertEqualObjects([_streamDelegate totalEventCount], @11, @"No other events should be emitted.");
}

- (void)testReadAllDataFromNSStreamWith1ByteRead {
    __block NSMutableData *data = [NSMutableData data];
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) {
        uint8_t byte;
        [(NSInputStream *)stream read:&byte maxLength:1];
        [data appendBytes:&byte length:1];
    }];
    [_streamDelegate handleEvent:NSStreamEventEndEncountered withBlock:^(NSStream *stream) {
        [stream close];
    }];
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"Stream will be closed when empty.");
    XCTAssertTrue([data length] == 9, @"All bytes should be read.");
}

- (void)testReadAllDataFromNSStreamWithHugeChunks {
    __block NSMutableData *data = [NSMutableData data];
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) {
        uint8_t bytes[1024];
        NSInteger readCount = [(NSInputStream *)stream read:bytes maxLength:1024];
        XCTAssertTrue(readCount == 9, @"Stream should return read bytes count.");
        [data appendBytes:bytes length:readCount];
    }];
    [_streamDelegate handleEvent:NSStreamEventEndEncountered withBlock:^(NSStream *stream) {
        [stream close];
    }];
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"Stream will be closed when empty.");
    XCTAssertTrue([data length] == 9, @"All bytes should be read.");
}

- (void)testReadAllDataFromNSStreamWhenEndEncountered {
    __block NSMutableData *data = [NSMutableData data];
    [_streamDelegate handleEvent:NSStreamEventHasBytesAvailable withBlock:^(NSStream *stream) {
        uint8_t bytes[1024];
        NSInteger readCount = [(NSInputStream *)stream read:bytes maxLength:1024];
        XCTAssertTrue(readCount == 9, @"Stream should return read bytes count.");
        [data appendBytes:bytes length:readCount];
    }];
    [_streamDelegate handleEvent:NSStreamEventEndEncountered withBlock:^(NSStream *stream) {
        uint8_t byte = 0x00;
        NSInteger readCount = [(NSInputStream *)stream read:&byte maxLength:1];
        XCTAssertTrue(readCount == 0, @"Stream should return 0 because end of the buffer was reached.");
        [stream close];
    }];
    POSRunLoopResult loopResult = [_runLoopRunner launchNSRunLoopWithStream:_blobStream delegate:_streamDelegate];
    XCTAssertTrue(loopResult == POSRunLoopResultDone, @"Stream will be closed when empty.");
    XCTAssertTrue([data length] == 9, @"All bytes should be read.");
}

@end
