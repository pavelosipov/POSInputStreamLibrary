//
//  POSBlobInputStreamPHAssetDataSource.h
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 07.12.15.
//  Copyright © 2015 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamBaseAssetDataSource.h"

/// Implementation of POSBlobInputStreamDataSource protocol for PHAsset from Photos.framework.
@interface POSBlobInputStreamPHAssetDataSource : POSBlobInputStreamBaseAssetDataSource

/// @brief The designated initializer.
/// @param assetID localIdentifier of the PHAsset.
/// @param temporaryFolderPath Path to the folder, where local copy of the asset
///                            may be placed it will not possible to avoid that.
///                            The folder will be created if it doesn't exist yet.
///                            Temporary file will be removed during stream closing.
/// @return Initialized instance of the data source which is ready for opening.
- (nonnull instancetype)initWithAssetID:(nonnull NSString *)assetID
                    temporaryFolderPath:(nonnull NSString *)path;

/// Deadly initializer.
- (nonnull instancetype)initWithAssetID:(nonnull id<NSCopying>)assetID NS_UNAVAILABLE;

@end
