NSInputStream for ALAsset
=========================
[![Version](http://img.shields.io/cocoapods/v/POSInputStreamLibrary.svg)](http://cocoapods.org/?q=POSInputStreamLibrary)

POSInputStreamLibrary contains `NSInputStream` implementation which uses `ALAsset`
as its data source. The main features of `POSBlobInputStream` are the following:

- Synchronous and asynchronous working modes.
- Autorefresh after `ALAsset` invalidation.
- Smart caching of `ALAsset` while reading its data.
- Using `NSStreamFileCurrentOffsetKey` property for read offset specification.
- Autorecovery after ALAssetRepresentation invalidation.
- Adjustment filters detection and applying for both iOS 7 and iOS 8 (new in 2.0.0).
- Integration with CFNetwork framework.
- Integration with AFNetworking (thanks to [@bancek](https://github.com/bancek)).

The category for `NSInputStream` defines initializers for the most common cases:

```objective-c
@interface NSInputStream (POS)
+ (NSInputStream *)pos_inputStreamWithAssetURL:(NSURL *)assetURL;
+ (NSInputStream *)pos_inputStreamWithAssetURL:(NSURL *)assetURL asynchronous:(BOOL)asynchronous;
+ (NSInputStream *)pos_inputStreamForCFNetworkWithAssetURL:(NSURL *)assetURL;
+ (NSInputStream *)pos_inputStreamForAFNetworkWithAssetURL:(NSURL *)assetURL
                                         openDispatchQueue:(dispatch_queue_t)openDispatchQueue;
@end
```

All of them require `NSURL` of `ALAsset`. `POSBlobInputStream` will query
ALAssetLibrary for `ALAsset` during the opening.

 
## Working modes

### Synchronous

In sync mode all methods of `POSInputStream` completely perform their work during
the call. If it is necessary to obtain some data from `ALAssetLibrary` the
calling thread will be blocked. This makes possible to work with a stream without
subscribing to its events, but at the same time neither method of NSInputStream
should be called from the main thread. The reason is that `ALAssetLibrary`
interacts with the client code in the main thread. Thus there will be a deadlock if
`POSBlobInputStream` waits the answer from `ALAssetLibrary` in a blocked main
thread. Here is an example of `POSBlobInputStream` usage in a sync mode for
calculating checksum of `ALAsset`.

```objective-c
NSInputStream *stream = [NSInputStream pos_inputStreamWithAssetURL:assetURL asynchronous:NO];
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [stream open];
    if ([stream streamStatus] == NSStreamStatusError) {
        // Error notification
        [stream close];
        return;
    }
    NSParameterAssert([stream streamStatus] == NSStreamStatusOpen);
    while ([stream hasBytesAvailable]) {
        uint8_t buffer[kBufferSize];
        const NSInteger readCount = [stream read:buffer maxLength:kBufferSize];
        if (readCount < 0) {
            break;
        } else {
            // Checksum update
        }
    }
    if ([stream streamStatus] != NSStreamStatusAtEnd) {
        // Error notification
    }
    [stream close];
}
```

### Asynchronous

In async mode all methods of `POSBlobInputStream` return immediately after call.
Client code should provide a delegate to the stream to receive information about its
status. This is the only way to know when the stream opened, when it has data to read
and about errors. You can see async version of checksum calculation below.

```objective-c
@interface ChecksumCalculator () <NSStreamDelegate>
@end

@implementation ChecksumCalculator

- (void)calculateChecksumForStream:(NSInputStream *)aStream {
    aStream.delegate = self;
    [aStream open];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [aStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        for (;;) { @autoreleasepool {
            if (![runLoop runMode:NSDefaultRunLoopMode
                       beforeDate:[NSDate dateWithTimeIntervalSinceNow:kRunLoopInterval]]) {
                break;
            }
            const NSStreamStatus streamStatus = [aStream streamStatus];
            if (streamStatus == NSStreamStatusError || streamStatus == NSStreamStatusClosed) {
                    break;
            }
        }}
    }});
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable: {
            [self updateChecksumForStream:aStream];
        } break;
        case NSStreamEventEndEncountered: {
            [self notifyChecksumCalculationCompleted];
            [aStream close];
        } break;
        case NSStreamEventErrorOccurred: {
            [self notifyErrorOccurred:[aStream streamError]];
            [aStream close];
        } break;
    }
}

@end
```

## Integrating with NSURLRequest

`POSBlobInputStream` provides `pos_inputStreamForCFNetworkWithAssetURL` initializer
for NSURLRequest integration. It takes into account the following CFNetwork "features":

- CFNetwork works with a stream in a sync mode. 
- CFNetowrk uses deprecated `CFReadStreamGetError` method to get error description from
the stream. This action will crash the app because of the bug in a "toll-free bridging"
implementation for NSInputStream. This is the reason why `streamStatus` method will never
return `NSStreamStatusError`. More over, `POSBlobInputStream` will not notify about its
status change via C-callbacks. The only way to receive actual status of the stream is via
`NSStreamDelagate` callback.

## Resources

* [How POSInputStreamLibrary was born inside Cloud Mail.Ru iOS Team (RU)](http://habr.ru/p/216247/)