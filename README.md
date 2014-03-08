NSInputStream for ALAsset
=========================

POSInputStreamLibrary contains `NSInputStream` implementation which uses `ALAsset`
as its data source. The main features of `POSBlobInputStream` are the following:

- Synchronous and asynchronous working modes.
- Autorefresh after `ALAsset` invalidation.
- Smart caching of `ALAsset` while reading its data.
- Using `NSStreamFileCurrentOffsetKey` property for read offset specification.

The category for `NSInputStream` defines initializers for the most common cases:

```objective-c
@interface NSInputStream (POS)
+ (NSInputStream *)pos_inputStreamWithAssetURL:(NSURL *)assetURL;
+ (NSInputStream *)pos_inputStreamWithAssetURL:(NSURL *)assetURL asynchronous:(BOOL)asynchronous;
+ (NSInputStream *)pos_inputStreamForCFNetworkWithAssetURL:(NSURL *)assetURL;
@end
```

All of them require `NSURL` of `ALAsset`. `POSBlobInputStream` will query
ALAssetLibrary for `ALAsset` during the opening.

 
## Working modes

### Synchronous

In sync mode all methods of `POSInputStream` completely perform their work during
the call. If it will be necessary to obtain some data from `ALAssetLibrary` the
calling thread will be blocked. This make it possible to work with a stream without
subscribing to its events, but at the same time neither method of NSInputStream
should be called from the main thread. The reason consists that `ALAssetLibrary`
interacts with the client code in the main thread. Thus there will be a deadlock if
`POSBlobInputStream` will wait the answer from `ALAssetLibrary` in a blocked main
thread. Here is an example of `POSBlobInputStream` usage in a sync mode for calculating
checksum of `ALAsset`.

```objective-c
NSInputStream *stream = [NSInputStream pos_inputStreamWithAssetURL:assetURL asynchronous:NO];
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [stream open];
    if ([stream streamStatus] == NSStreamStatusError) {
        // Error notification
        return;
    }
    NSParameterAssert([stream streamStatus] == NSStreamStatusOpen);
    while ([stream hasBytesAvailable]) {
        uint8_t buffer[kBufferSize];
        const NSInteger readCount = [stream read:buffer maxLength:kBufferSize];
        if (readCount < 0) {
            // Error notification
            return;
        } else {
            // Checksum update
        }
    }
    if ([stream streamStatus] != NSStreamStatusAtEnd) {
        // Error notification
        return;
    }
    [stream close];
}
```
