//
//  POSFastAssetReader.m
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 08.05.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import "POSFastAssetReader.h"

static uint64_t const kAssetCacheBufferSize = 131072;

@interface POSFastAssetReader ()
@property (nonatomic, readonly) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, readonly) ALAsset *asset;
@property (nonatomic, readonly) ALAssetRepresentation *assetRepresentation;
@end

@implementation POSFastAssetReader {
    uint8_t _assetCache[kAssetCacheBufferSize];
    POSLength _assetSize;
    POSLength _assetCacheSize;
    POSLength _assetCacheOffset;
    POSLength _assetCacheInternalOffset;
}

- (instancetype)initWithAsset:(ALAsset *)asset
          assetRepresentation:(ALAssetRepresentation *)assetRepresentation
                assetsLibrary:(ALAssetsLibrary *)assetsLibrary {
    NSParameterAssert(asset);
    NSParameterAssert(assetRepresentation);
    NSParameterAssert(assetsLibrary);
    if (self = [super init]) {
        _asset = asset;
        _assetRepresentation = assetRepresentation;
        _assetsLibrary = assetsLibrary;
    }
    return self;
}

#pragma mark - POSAssetReader

- (void)openFromOffset:(POSLength)offset completionHandler:(void (^)(POSLength, NSError *))completionHandler {
    NSError *error;
    [self p_refillCacheFromOffset:offset error:&error];
    completionHandler(_assetSize, error);
}

- (BOOL)hasBytesAvailableFromOffset:(POSLength)offset {
    if ([self p_cachedBytesCount] <= 0) {
        return NO;
    }
    return offset < _assetCacheOffset + _assetCacheSize;
}

- (BOOL)prepareForNewOffset:(POSLength)offset {
    return [self p_refillCacheFromOffset:offset error:nil];
}

- (NSInteger)read:(uint8_t *)buffer
       fromOffset:(POSLength)offset
        maxLength:(NSUInteger)maxLength
            error:(NSError **)error {
    const POSLength readResult = MIN(maxLength, [self p_cachedBytesCount]);
    memcpy(buffer, _assetCache + _assetCacheInternalOffset, (unsigned long)readResult);
    _assetCacheInternalOffset += readResult;
    const POSLength nextReadOffset = offset + readResult;
    if ([self p_cachedBytesCount] <= 0 ||
        [self p_unreadBytesCountFromOffset:nextReadOffset] > 0) {
        [self p_refillCacheFromOffset:nextReadOffset error:error];
    }
    return (NSInteger)readResult;
}

#pragma mark - Private

- (POSLength)p_unreadBytesCountFromOffset:(POSLength)offset {
    return _assetSize - offset;
}

- (POSLength)p_cachedBytesCount {
    return _assetCacheSize - _assetCacheInternalOffset;
}

- (BOOL)p_refillCacheFromOffset:(POSLength)offset error:(NSError **)error {
    const NSUInteger readResult = [_assetRepresentation getBytes:_assetCache
                                                      fromOffset:offset
                                                          length:kAssetCacheBufferSize
                                                           error:error];
    if (readResult <= 0) {
        if (error) {
            NSString *desc = [NSString stringWithFormat:@"Failed to read asset bytes in range %@ from asset of size %@.",
                              NSStringFromRange(NSMakeRange((NSUInteger)offset, (NSUInteger)kAssetCacheBufferSize)),
                              @(_assetSize)];
            *error = [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                         code:-2000
                                     userInfo:@{NSLocalizedDescriptionKey: desc}];
        }
        return NO;
    }
    _assetSize = [_assetRepresentation size];
    _assetCacheSize = readResult;
    _assetCacheOffset = offset;
    _assetCacheInternalOffset = 0;
    return YES;
}

@end
