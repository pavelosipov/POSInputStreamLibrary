//
//  POSBlobInputStreamBaseAssetDataSource.m
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 08.12.15.
//  Copyright © 2015 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamBaseAssetDataSource.h"
#import "POSLocking.h"

NSString * const POSBlobInputStreamAssetDataSourceErrorDomain = @"com.github.pavelosipov.POSBlobInputStreamAssetDataSource";

static const char * const POSInputStreamSharedOpenDispatchQueueName = "com.github.pavelosipov.POSInputStreamSharedOpenDispatchQueue";

@interface NSError (POSBlobInputStreamAssetDataSource)
+ (NSError *)pos_assetOpenErrorWithID:(id)assetID reason:(NSError *)reason;
+ (NSError *)pos_assetReadErrorWithID:(id)assetID reason:(NSError *)reason;
@end

#pragma mark -

@interface POSBlobInputStreamBaseAssetDataSource ()
@property (nonatomic) NSError *error;
@property (nonatomic, readonly, nonnull) id assetID;
@property (nonatomic, nullable) id<POSAssetReader> assetReader;
@property (nonatomic) POSLength assetSize;
@property (nonatomic) POSLength readOffset;
@end

@implementation POSBlobInputStreamBaseAssetDataSource
@dynamic openCompleted, hasBytesAvailable, atEnd;

#pragma mark Lifecycle

- (instancetype)initWithAssetID:(id)assetID {
    NSParameterAssert(assetID);
    if (self = [super init]) {
        _assetID = [assetID copy];
    }
    return self;
}

#pragma mark POSBlobInputStreamDataSource

- (BOOL)isOpenCompleted {
    return _assetSize > 0;
}

- (void)open {
    if (![self isOpenCompleted]) {
        [self p_open];
    }
}

- (void)setAssetSize:(POSLength)assetSize {
    const BOOL shouldEmitOpenCompletedEvent = ![self isOpenCompleted];
    if (shouldEmitOpenCompletedEvent) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceOpenCompletedKeyPath];
    }
    _assetSize = assetSize;
    if (shouldEmitOpenCompletedEvent) {
        [self didChangeValueForKey:POSBlobInputStreamDataSourceOpenCompletedKeyPath];
    }
}

- (BOOL)hasBytesAvailable {
    return [_assetReader hasBytesAvailableFromOffset:_readOffset];
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
    if (_assetReader) {
        return [_assetReader prepareForNewOffset:_readOffset];
    }
    return YES;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)bufferLength {
    return NO;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength {
    NSParameterAssert(buffer);
    NSParameterAssert(maxLength > 0);
    if (self.atEnd) {
        return 0;
    }
    NSError *error;
    const POSLength readResult = [_assetReader read:buffer
                                         fromOffset:_readOffset
                                          maxLength:maxLength
                                              error:&error];
    const POSLength readOffset = _readOffset + readResult;
    NSParameterAssert(readOffset <= _assetSize);
    const BOOL atEnd = readOffset >= _assetSize;
    if (atEnd) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
    }
    _readOffset = readOffset;
    if (atEnd) {
        [self didChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
    } else if (error) {
        [self p_open];
    }
    return (NSInteger)readResult;
}

#pragma mark Public

+ (dispatch_queue_t)sharedOpenDispatchQueue {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(POSInputStreamSharedOpenDispatchQueueName, NULL);
    });
    return queue;
}

#pragma mark Abstract

- (void)abstract_openAssetWithID:(id)assetID
                 completionBlock:(void (^)(id<POSAssetReader> _Nullable, NSError * _Nullable))blockName {
    [NSException raise:NSInternalInconsistencyException
                format:@"Template method '%@' is not implemented.", NSStringFromSelector(_cmd)];
}

#pragma mark Private

- (void)p_open {
    id<POSLocking> lock = [self p_lockForOpening];
    [lock lock];
    dispatch_async(self.openDispatchQueue ?: dispatch_get_main_queue(), ^{ @autoreleasepool {
        [self abstract_openAssetWithID:_assetID completionBlock:^(id<POSAssetReader> assetReader, NSError * error) {
            if (!assetReader) {
                self.error = [NSError pos_assetOpenErrorWithID:_assetID reason:error];
            } else {
                self.assetReader = assetReader;
                [assetReader openFromOffset:_readOffset completionHandler:^(POSLength assetSize, NSError *error) {
                    if (error != nil || assetSize <= 0 || (_assetSize != 0 && _assetSize != assetSize)) {
                        self.error = [NSError pos_assetOpenErrorWithID:_assetID reason:error];
                    } else {
                        self.assetSize = assetSize;
                    }
                }];
            }
            [lock unlock];
        }];
    }});
    [lock waitWithTimeout:DISPATCH_TIME_FOREVER];
}

- (id<POSLocking>)p_lockForOpening {
    if ([self shouldOpenSynchronously]) {
        if (!self.openDispatchQueue) {
            // If you want open stream synchronously you should
            // do that in some worker thread to avoid deadlock.
            NSParameterAssert(![[NSThread currentThread] isMainThread]);
        }
        return [POSGCDLock new];
    } else {
        return [POSDummyLock new];
    }
}

@end

#pragma mark -

@implementation NSError (POSBlobInputStreamAssetDataSource)

+ (NSError *)pos_assetOpenErrorWithID:(id)assetID reason:(NSError *)reason {
    NSString *description = [NSString stringWithFormat:@"Failed to open asset ID '%@'", assetID];
    if (reason) {
        return [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                   code:POSBlobInputStreamAssetDataSourceErrorCodeOpen
                               userInfo:@{ NSLocalizedDescriptionKey: description, NSUnderlyingErrorKey: reason }];
    } else {
        return [NSError errorWithDomain:POSBlobInputStreamAssetDataSourceErrorDomain
                                   code:POSBlobInputStreamAssetDataSourceErrorCodeOpen
                               userInfo:@{ NSLocalizedDescriptionKey: description }];
    }
}

+ (NSError *)pos_assetReadErrorWithID:(id)assetID reason:(NSError *)reason {
    NSString *description = [NSString stringWithFormat:@"Failed to read asset with ID '%@'", assetID];
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
