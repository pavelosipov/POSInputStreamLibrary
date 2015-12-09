//
//  POSFastAssetReader.h
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 08.05.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import "POSAssetReader.h"

@interface POSFastAssetReader : NSObject <POSAssetReader>

/// The designated initializer.
- (nonnull instancetype)initWithAsset:(nonnull ALAsset *)asset
                  assetRepresentation:(nonnull ALAssetRepresentation *)assetRepresentation
                        assetsLibrary:(nonnull ALAssetsLibrary *)assetsLibrary;

/// Deadly initializer.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Deadly factory method.
+ (nonnull instancetype)new NS_UNAVAILABLE;

@end
