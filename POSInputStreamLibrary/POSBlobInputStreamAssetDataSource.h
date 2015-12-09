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

/// The designated initializer.
- (nonnull instancetype)initWithAssetURL:(nonnull NSURL *)assetURL;

/// Deadly initializer.
- (nonnull instancetype)initWithAssetID:(nonnull id<NSCopying>)assetID NS_UNAVAILABLE;

@end
