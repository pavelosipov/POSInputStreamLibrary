//
//  POSBlobInputStreamPHAssetDataSource.m
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 07.12.15.
//  Copyright © 2015 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamPHAssetDataSource.h"
#import "POSImageReaderIOS8.h"
#import "POSFastAssetReader.h"
#import "POSLocking.h"
#import <Photos/Photos.h>

@interface POSBlobInputStreamPHAssetDataSource ()
@property (nonatomic, readonly) NSString *temporaryFolderPath;
@end

@implementation POSBlobInputStreamPHAssetDataSource

#pragma mark Lifecycle

- (instancetype)initWithAssetID:(NSString *)assetID temporaryFolderPath:(NSString *)path {
    NSParameterAssert(assetID);
    NSParameterAssert(path);
    if (self = [super initWithAssetID:assetID]) {
        _temporaryFolderPath = [path copy];
    }
    return self;
}

#pragma mark POSBlobInputStreamBaseAssetDataSource

- (void)abstract_openAssetWithID:(id)assetID completionBlock:(void (^)(id<POSAssetReader>, NSError *))completionBlock {
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.wantsIncrementalChangeDetails = NO;
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetID] options:fetchOptions];
    if (fetchResult.count == 0) {
        completionBlock(nil, nil);
        return;
    }
    PHAsset *asset = [fetchResult firstObject];
    if (asset.mediaType == PHAssetMediaTypeImage ||
        asset.mediaSubtypes != 0) {
        POSImageReaderIOS8 *assetReader = [[POSImageReaderIOS8 alloc] initWithAsset:asset];
        assetReader.suspiciousSize = self.adjustedImageMaximumSize;
        assetReader.completionDispatchQueue = self.openDispatchQueue;
        completionBlock(assetReader, nil);
    } else {
        // Trying:
        // 1. ImageDataAssetReader
        // 2. ALAssetReader
        // 3. DefaultAssetReader
        completionBlock(nil, nil);
    }
}

@end
