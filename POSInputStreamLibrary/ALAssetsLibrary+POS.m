//
//  ALAssetsLibrary+POS.m
//  POSInputStreamLibrary
//
//  Created by Osipov on 31.08.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import "ALAssetsLibrary+POS.h"

@implementation ALAssetsLibrary (POS)

- (void)mrc_assetForURL:(NSURL *)assetURL
            resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock
           failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
    [self assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        if (asset) {
            resultBlock(asset);
            return;
        }
        __block ALAsset *groupAsset;
        [self
         enumerateGroupsWithTypes:ALAssetsGroupPhotoStream
         usingBlock:^(ALAssetsGroup *group, BOOL *stopEnumeratingGroups) {
             if (groupAsset) {
                 resultBlock(groupAsset);
                 *stopEnumeratingGroups = YES;
                 return;
             }
             if (!group) {
                 resultBlock(nil);
                 return;
             }
             [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stopEnumeratingAssets) {
                 if (!asset) {
                     return;
                 }
                 // For iOS 5 you should use another check:
                 // [[[asset valueForProperty:ALAssetPropertyURLs] allObjects] lastObject]
                 if ([[asset valueForProperty:ALAssetPropertyAssetURL] isEqual:assetURL]) {
                     groupAsset = asset;
                     *stopEnumeratingAssets = YES;
                 }
             }];
         } failureBlock:failureBlock];
    } failureBlock:failureBlock];
}

@end
