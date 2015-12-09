//
//  POSBlobInputStreamBaseAssetDataSource.h
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 08.12.15.
//  Copyright © 2015 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamDataSource.h"
#import "POSAssetReader.h"

/// Implementation of common functionality of varisous kinds of Asset DataSources.
@interface POSBlobInputStreamBaseAssetDataSource : NSObject <POSBlobInputStreamDataSource>

/// @brief Indicates that the stream should block calling thread until opening
///        will not complete.
/// @discussion This flag should be YES for streams which are used in NSURLRequest
///             or some other synchronous client's code. The only limitation of
///             sync mode is that you can not use it while working with a stream
///             in the main thread.
@property (nonatomic, getter = shouldOpenSynchronously) BOOL openSynchronously;

/// @brief Dispatch queue for fetching ALAsset from ALAssetsLibrary.
/// @discussion By default when stream is opened, current dispatch queue is locked and
///             ALAsset is retrieved on main dispatch queue. AFNetworking also uses
///             main dispatch queue to open NSInputStream so we cannot use it.
@property (nonatomic, nullable) dispatch_queue_t openDispatchQueue;

/// Shared queue for fetching ALAssets from ALAssetsLibrary.
+ (nonnull dispatch_queue_t)sharedOpenDispatchQueue;

/// Abstract method for stream opening, which should be implemented in subsclasses.
- (void)abstract_openAssetWithID:(nonnull id)assetID
                 completionBlock:(nonnull void(^)(id<POSAssetReader> _Nullable assetReader, NSError * _Nullable error))completionBlock;

/// The designated initializer.
- (nonnull instancetype)initWithAssetID:(nonnull id<NSCopying>)assetID;

/// Deadly initializer.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Deadly factory method.
+ (nonnull instancetype)new NS_UNAVAILABLE;

@end
