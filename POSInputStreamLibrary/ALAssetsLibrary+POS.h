//
//  ALAssetsLibrary+POS.h
//  POSInputStreamLibrary
//
//  Created by Osipov on 31.08.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetsLibrary (POS)

- (void)pos_assetForURL:(NSURL *)assetURL
            resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock
           failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock;

@end
