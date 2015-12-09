//
//  POSImageReaderIOS8.m
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 12.05.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import "POSImageReaderIOS8.h"

@interface POSImageReaderIOS8 ()
@property (nonatomic, readonly) PHAsset *asset;
@property (nonatomic) NSData *imageData;
@end

@implementation POSImageReaderIOS8

- (instancetype)initWithAsset:(PHAsset *)asset {
    NSParameterAssert(asset);
    if (self = [super init]) {
        _suspiciousSize = LONG_LONG_MAX;
        _asset = asset;
    }
    return self;
}

#pragma mark POSAssetReader

- (void)openFromOffset:(POSLength)offset completionHandler:(void (^)(POSLength, NSError *))completionHandler {
    void (^openCompletionBlock)(NSData *, NSError *) = ^void(NSData *assetData, NSError *error) {
        self.imageData = assetData;
        dispatch_async(self.completionDispatchQueue ?: dispatch_get_main_queue(), ^{
            completionHandler([_imageData length], error);
        });
    };
    [self p_fetchAssetDataForAsset:_asset completionBlock:^(NSData *assetData, NSError *error) {
        if ([assetData length] <= _suspiciousSize) {
            [self p_fetchAssetDataForAsset:_asset completionBlock:openCompletionBlock];
        } else {
            openCompletionBlock(assetData, error);
        }
    }];
}

- (BOOL)hasBytesAvailableFromOffset:(POSLength)offset {
    return [_imageData length] - offset > 0;;
}

- (BOOL)prepareForNewOffset:(POSLength)offset {
    return YES;
}

- (NSInteger)read:(uint8_t *)buffer
       fromOffset:(POSLength)offset
        maxLength:(NSUInteger)maxLength
            error:(NSError **)error {
    const POSLength readResult = MIN(maxLength, MAX([_imageData length] - offset, 0));
    NSRange dataRange = (NSRange){
        .location = (NSUInteger)offset,
        .length = (NSUInteger)readResult
    };
    [_imageData getBytes:buffer range:dataRange];
    return (NSInteger)readResult;
}

#pragma mark Private

- (void)p_fetchAssetDataForAsset:(PHAsset *)asset
                 completionBlock:(void (^)(NSData *assetData, NSError *error))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ @autoreleasepool {
        PHImageManager *imageManager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeNone;
        options.synchronous = YES;
        options.networkAccessAllowed = NO;
        [imageManager
         requestImageDataForAsset:asset
         options:options
         resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            if (info[PHImageErrorKey] != nil) {
                NSError *error = [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                                     code:211
                                                 userInfo:@{ NSLocalizedDescriptionKey: @"Failed to fetch data for image.",
                                                             NSUnderlyingErrorKey: info[PHImageErrorKey]}];
                completionHandler(nil, error);
            } else if ([info[PHImageCancelledKey] boolValue]) {
                NSError *error = [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                                     code:212
                                                 userInfo:@{ NSLocalizedDescriptionKey: @"Fetching data for image was canceled."}];
                completionHandler(nil, error);
            } else if ([info[PHImageResultIsInCloudKey] boolValue]) {
                NSError *error = [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                                     code:213
                                                 userInfo:@{ NSLocalizedDescriptionKey: @"Image is located in the cloud."}];
                completionHandler(nil, error);
            } else {
                completionHandler(imageData, nil);
            }
        }];
    }});
}

@end
