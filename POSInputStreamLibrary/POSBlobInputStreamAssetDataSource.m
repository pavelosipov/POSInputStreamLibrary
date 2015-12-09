//
//  POSBlobInputStreamAssetDataSource.m
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 06.05.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamAssetDataSource.h"
#import "POSFastAssetReader.h"
#import "POSAdjustedAssetReaderIOS7.h"
#import "POSAdjustedAssetReaderIOS8.h"
#import "ALAssetsLibrary+POS.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

@interface POSBlobInputStreamAssetDataSource ()
@end

@implementation POSBlobInputStreamAssetDataSource

#pragma mark Lifecycle

- (instancetype)initWithAssetURL:(NSURL *)assetURL {
    NSParameterAssert(assetURL);
    if (self = [super initWithAssetID:assetURL]) {
        _adjustedJPEGCompressionQuality = .93f;
        _adjustedImageMaximumSize = 1024 * 1024;
    }
    return self;
}

#pragma mark POSBlobInputStreamBaseAssetDataSource

- (void)abstract_openAssetWithID:(NSURL *)assetURL completionBlock:(void (^)(id<POSAssetReader>, NSError *))completionBlock {
    ALAssetsLibrary *assetsLibrary = [ALAssetsLibrary new];
    [assetsLibrary pos_assetForURL:assetURL resultBlock:^(ALAsset *asset, ALAssetsGroup *assetsGroup) {
        ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
        if (assetRepresentation) {
            id<POSAssetReader> assetReader = [self p_assetReaderWithAsset:asset
                                                      assetRepresentation:assetRepresentation
                                                               assetGroup:assetsGroup
                                                            assetsLibrary:assetsLibrary];
            completionBlock(assetReader, nil);
        } else {
            completionBlock(nil, nil);
        }
    } failureBlock:^(NSError *error) {
        completionBlock(nil, error);
    }];
}

- (id<POSAssetReader>)p_assetReaderWithAsset:(ALAsset *)asset
                         assetRepresentation:(ALAssetRepresentation *)assetRepresentation
                                  assetGroup:(ALAssetsGroup *)assetGroup
                               assetsLibrary:(ALAssetsLibrary *)assetsLibrary {
    if (assetGroup || !UTTypeConformsTo((__bridge CFStringRef)assetRepresentation.UTI, kUTTypeImage)) {
        return [[POSFastAssetReader alloc]
                initWithAsset:asset
                assetRepresentation:assetRepresentation
                assetsLibrary:assetsLibrary];
    }
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0 &&
        assetRepresentation.size <= _adjustedImageMaximumSize) {
        POSAdjustedAssetReaderIOS8 *assetReader = [[POSAdjustedAssetReaderIOS8 alloc]
                                                   initWithAsset:asset
                                                   assetRepresentation:assetRepresentation
                                                   assetsLibrary:assetsLibrary];
        assetReader.suspiciousSize = _adjustedImageMaximumSize;
        assetReader.completionDispatchQueue = self.openDispatchQueue;
        return assetReader;
    }
    if (assetRepresentation.metadata[@"AdjustmentXMP"] != nil) {
        POSAdjustedAssetReaderIOS7 *assetReader = [[POSAdjustedAssetReaderIOS7 alloc]
                                                   initWithAsset:asset
                                                   assetRepresentation:assetRepresentation
                                                   assetsLibrary:assetsLibrary];
        assetReader.JPEGCompressionQuality = _adjustedJPEGCompressionQuality;
        assetReader.completionDispatchQueue = self.openDispatchQueue;
        return assetReader;
    }
    return [[POSFastAssetReader alloc]
            initWithAsset:asset
            assetRepresentation:assetRepresentation
            assetsLibrary:assetsLibrary];
}

@end
