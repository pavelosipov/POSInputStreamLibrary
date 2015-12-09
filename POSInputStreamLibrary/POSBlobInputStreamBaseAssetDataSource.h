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

/// @brief The suspicious size of assets to detect adjusted photos in iOS 8 gallery.
///        The default value is 1M.
/// @discussion System Camera app has a strange behaviour on iOS 8. If you turn ON
///             built-in filters and make a photo with them, then metadata of that
///             photo will not have adjustent XML. At the same time the size of the
///             asset will be something about 150-300K instead of usual 1.5-3M. This
///             property is used for detecting that kind of adjusted images on iOS 8.
///             If asset is smaller than adjustedImageMaximumSize value then iOS 8
///             Photos framework will be used for reading asset's data. The drawback
///             is the app will consume much more RAM, because instead of streaming
///             asset directly from ALAssetsLibrary it will allocate RAM for the whole
///             UIImage at once.
/// @remarks See comments in POSAdjustedAssetReaderIOS8.h for more info.
@property (nonatomic, assign) long long adjustedImageMaximumSize;

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
