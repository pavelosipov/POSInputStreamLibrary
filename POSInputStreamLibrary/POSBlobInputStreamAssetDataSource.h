//
//  POSBlobInputStreamAssetDataSource.h
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 16.07.13.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamBaseAssetDataSource.h"

/// Data source for streaming ALAsset from AssetsLibrary.
@interface POSBlobInputStreamAssetDataSource : POSBlobInputStreamBaseAssetDataSource

/// @brief Value within [0, 1] range which determines compression quality for
///        adjusted JPEGs. The default value is 0.93.
/// @discussion Adjustment filters on iOS7 applied by data source manually using
///             hardware acceleration. After applying them on JPEG images
///             UIImageJPEGRepresentation function will be used to get raw bytes
///             for resulted UIImage. The value of that property will be bypassed
///             to it as a second argument.
@property (nonatomic, assign) CGFloat adjustedJPEGCompressionQuality;

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

/// The designated initializer.
- (nonnull instancetype)initWithAssetURL:(nonnull NSURL *)assetURL;

/// Deadly initializer.
- (nonnull instancetype)initWithAssetID:(nonnull id<NSCopying>)assetID NS_UNAVAILABLE;

@end
