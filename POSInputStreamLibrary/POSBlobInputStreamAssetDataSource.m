//
//  POSBlobInputStreamAssetDataSource.m
//  POSBlobInputStreamLibrary
//
//  Created by Pavel Osipov on 16.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamAssetDataSource.h"

typedef long long POSLength;

NSString * const POSBlobInputStreamAssetDataSourceErrorDomain = @"com.github.pavelosipov.POSBlobInputStreamAssetDataSource";

static uint64_t const kAssetCacheBufferSize = 131072;

typedef NS_ENUM(NSInteger, UpdateCacheMode) {
    UpdateCacheModeReopenWhenError,
    UpdateCacheModeFailWhenError
};

#pragma mark - Locking

@protocol Locking <NSLocking>
- (BOOL)waitWithTimeout:(dispatch_time_t)timeout;
@end

@interface GCDLock : NSObject <Locking>
@end

@implementation GCDLock {
    dispatch_semaphore_t semaphore_;
}

- (void)lock {
    semaphore_ = dispatch_semaphore_create(0);
}

- (void)unlock {
    dispatch_semaphore_signal(semaphore_);
}

- (BOOL)waitWithTimeout:(dispatch_time_t)timeout {
    return dispatch_semaphore_wait(semaphore_, timeout) == 0;
}

@end

@interface DummyLock : NSObject <Locking>
@end

@implementation DummyLock
- (void)lock {}
- (void)unlock {}
- (BOOL)waitWithTimeout:(dispatch_time_t)timeout { return YES; }
@end

#pragma mark - NSError (POSBlobInputStreamAssetDataSource)

@interface NSError (POSBlobInputStreamAssetDataSource)
+ (NSError *)pos_assetOpenError;
@end

@implementation NSError (POSBlobInputStreamAssetDataSource)

+ (NSError *)pos_assetOpenError {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Failed to open ALAsset stream." };
    return [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                               code:POSBlobInputStreamAssetDataSourceErrorCodeOpen
                           userInfo:userInfo];
}

+ (NSError *)pos_assetReadErrorWithURL:(NSURL *)assetURL reason:(NSError *)reason {
    NSString *description = [NSString stringWithFormat:@"Failed to read asset with URL %@", assetURL];
    if (reason) {
        return [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                   code:POSBlobInputStreamAssetDataSourceErrorCodeRead
                               userInfo:@{ NSLocalizedDescriptionKey: description, NSUnderlyingErrorKey: reason }];
    } else {
        return [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                   code:POSBlobInputStreamAssetDataSourceErrorCodeRead
                               userInfo:@{ NSLocalizedDescriptionKey: description }];
    }
}

@end

#pragma mark - POSBlobInputStreamAssetDataSource

@interface POSBlobInputStreamAssetDataSource ()
@property (nonatomic, readwrite) NSError *error;
@end

@implementation POSBlobInputStreamAssetDataSource {
    NSURL *_assetURL;
    ALAsset *_asset;
    ALAssetsLibrary *_assetsLibrary;
    ALAssetRepresentation *_assetRepresentation;
    POSLength _assetSize;
    POSLength _readOffset;
    uint8_t _assetCache[kAssetCacheBufferSize];
    POSLength _assetCacheSize;
    POSLength _assetCacheOffset;
    POSLength _assetCacheInternalOffset;
}

@dynamic openCompleted, hasBytesAvailable, atEnd;

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Unexpected deadly init invokation '%@', use %@ instead.",
                                           NSStringFromSelector(_cmd),
                                           NSStringFromSelector(@selector(initWithAssetURL:))]
                                 userInfo:nil];
}

- (id)initWithAssetURL:(NSURL *)assetURL {
    NSParameterAssert(assetURL);
    if (self = [super init]) {
        _openSynchronously = NO;
        _assetURL = assetURL;
        _assetCacheSize = 0;
        _assetCacheOffset = 0;
        _assetCacheInternalOffset = 0;
    }
    return self;
}

#pragma mark - POSBlobInputStreamDataSource

- (BOOL)isOpenCompleted {
    return _assetRepresentation != nil;
}

- (void)open {
    if (![self isOpenCompleted]) {
        [self p_open];
    }
}

- (BOOL)hasBytesAvailable {
    return [self p_availableBytesCount] > 0;
}

- (BOOL)isAtEnd {
    return _assetSize <= _readOffset;
}

- (id)propertyForKey:(NSString *)key {
    if (![key isEqualToString:NSStreamFileCurrentOffsetKey]) {
        return nil;
    }
    return @(_readOffset);
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    if (![key isEqualToString:NSStreamFileCurrentOffsetKey]) {
        return NO;
    }
    if (![property isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    const long long requestedOffest = [property longLongValue];
    if (requestedOffest < 0) {
        return NO;
    }
    _readOffset = requestedOffest;
    if ([self isOpenCompleted]) {
        [self p_updateCacheInMode:UpdateCacheModeReopenWhenError];
    }
    return YES;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength {
    NSParameterAssert(buffer);
    NSParameterAssert(maxLength > 0);
    if (self.atEnd) {
        return 0;
    }
    const POSLength readResult = MIN(maxLength, [self p_availableBytesCount]);
    memcpy(buffer, _assetCache + _assetCacheInternalOffset, (unsigned long)readResult);
    _assetCacheInternalOffset += readResult;
    const POSLength readOffset = _readOffset + readResult;
    NSParameterAssert(readOffset <= _assetSize);
    const BOOL atEnd = readOffset >= _assetSize;
    if (atEnd) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
    }
    _readOffset = readOffset;
    if (atEnd) {
        [self didChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
    } else if (![self hasBytesAvailable]) {
        [self p_updateCacheInMode:UpdateCacheModeReopenWhenError];
    }
    return (NSInteger)readResult;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)bufferLength {
    return NO;
}

#pragma mark - POSBlobInputStreamDataSource Private

- (void)p_open {
    id<Locking> lock = [self p_lockForOpening];
    [lock lock];
    dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        [_assetsLibrary assetForURL:_assetURL resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
            if (assetRepresentation != nil) {
                [self p_updateAsset:asset withAssetRepresentation:assetRepresentation];
                [self p_updateCacheInMode:UpdateCacheModeFailWhenError];
            } else {
                [self setError:[NSError pos_assetOpenError]];
            }
            [lock unlock];
        } failureBlock:^(NSError *error) {
            [self setError:[NSError pos_assetOpenError]];
            [lock unlock];
        }];
    }});
    [lock waitWithTimeout:DISPATCH_TIME_FOREVER];
}

- (void)p_updateAsset:(ALAsset *)asset withAssetRepresentation:(ALAssetRepresentation *)assetRepresentation {
    const BOOL shouldEmitOpenCompletedEvent = ![self isOpenCompleted];
    if (shouldEmitOpenCompletedEvent) [self willChangeValueForKey:POSBlobInputStreamDataSourceOpenCompletedKeyPath];
    _asset = asset;
    _assetRepresentation = assetRepresentation;
    _assetSize = [assetRepresentation size];
    if (shouldEmitOpenCompletedEvent) [self didChangeValueForKey:POSBlobInputStreamDataSourceOpenCompletedKeyPath];
}

- (void)p_updateCacheInMode:(UpdateCacheMode)mode {
    NSError *readError = nil;
    const NSUInteger readResult = [_assetRepresentation getBytes:_assetCache
                                                      fromOffset:_readOffset
                                                          length:kAssetCacheBufferSize
                                                           error:&readError];
    if (readResult > 0) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceHasBytesAvailableKeyPath];
        _assetCacheSize = readResult;
        _assetCacheOffset = _readOffset;
        _assetCacheInternalOffset = 0;
        [self didChangeValueForKey:POSBlobInputStreamDataSourceHasBytesAvailableKeyPath];
    } else {
        switch (mode) {
            case UpdateCacheModeReopenWhenError: {
                [self p_open];
            } break;
            case UpdateCacheModeFailWhenError: {
                [self setError:[NSError pos_assetReadErrorWithURL:_assetURL reason:readError]];
            } break;
        }
    }
}

- (POSLength)p_availableBytesCount {
    return _assetCacheSize - _assetCacheInternalOffset;
}

- (id<Locking>)p_lockForOpening {
    if ([self shouldOpenSynchronously]) {
        // If you want open stream synchronously you should do that in some worker thread to avoid deadlock.
        NSParameterAssert(![[NSThread currentThread] isMainThread]);
        return [GCDLock new];
    } else {
        return [DummyLock new];
    }
}

@end
