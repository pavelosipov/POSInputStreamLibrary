NSInputStream for ALAsset
=========================

POSInputStreamLibrary contains `NSInputStream` implementation which uses `ALAsset` as its data source. The main features of `POSBlobInputStream` are the following:

- Synchronous and asynchronous working modes.
- Autorefresh after `ALAsset` invalidation.
- Smart caching of `ALAsset` while reading its data.
- Using `NSStreamFileCurrentOffsetKey` property for initial offset specification.

The category for `NSInputStream` defines initializers for the most common cases:

```objective-c
@interface NSInputStream (POS)
+ (NSInputStream *)pos_inputStreamWithAssetURL:(NSURL *)assetURL;
+ (NSInputStream *)pos_inputStreamWithAssetURL:(NSURL *)assetURL asynchronous:(BOOL)asynchronous;
+ (NSInputStream *)pos_inputStreamForCFNetworkWithAssetURL:(NSURL *)assetURL;
@end
```

All of them require `NSURL` of `ALAsset`. `POSBlobInputStream` will query ALAssetLibrary for `ALAsset` during the opening.

 
 ## Synchronous and asynchronous working modes

