//
//  POSBlobInputStreamMockDataSource.m
//  POSBlobInputStreamTests
//
//  Created by Pavel Osipov on 16.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamMockDataSource.h"

@interface POSBlobInputStreamMockDataSource ()
@property (nonatomic, readwrite, getter = isOpenCompleted) BOOL openCompleted;
@property (nonatomic, readwrite) NSError *error;
@end

@implementation POSBlobInputStreamMockDataSource {
    NSUInteger _readOffset;
    long long _length;
    NSError *_openError;
}

@dynamic hasBytesAvailable, atEnd;

- (id)init {
    return [self initWithLength:0];
}

- (id)initWithLength:(long long)aLength {
    if (self = [super init]) {
        _length = aLength;
    }
    return self;
}

- (id)initWithOpenError:(NSError *)error {
    if (self = [super init]) {
        _openError = error;
    }
    return self;
}

#pragma mark - POSBlobInputStreamDataSource

- (void)open {
    if (_openError) {
        [self setError:_openError];
    } else {
        [self setOpenCompleted:YES];
    }
}

- (void)setOpenCompleted:(BOOL)openCompleted {
    _openCompleted = openCompleted;
}

- (BOOL)hasBytesAvailable {
    return [self isOpenCompleted] && (_length > _readOffset);
}

- (BOOL)isAtEnd {
    return _length == _readOffset;
}

- (id)propertyForKey:(NSString *)key {
    return nil;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return NO;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength {
    const NSUInteger expectedReadCount = (NSUInteger)MIN(maxLength, _length - _readOffset);
    memset(buffer, 0, expectedReadCount);
    const NSInteger readOffset = _readOffset + expectedReadCount;
    if (readOffset == _length) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
        _readOffset = readOffset;
        [self didChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
    } else {
        _readOffset = readOffset;
    }
    return expectedReadCount;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)bufferLength {
    return NO;
}

#pragma mark - NSObject KVO

+ (NSSet *)keyPathsForValuesAffectingHasBytesAvailable {
    return [NSSet setWithObjects:
            POSBlobInputStreamDataSourceOpenCompletedKeyPath,
            POSBlobInputStreamDataSourceAtEndKeyPath,
            nil];
}

+ (NSSet *)keyPathsForValuesAffectingAtEnd {
    return [NSSet setWithObject:POSBlobInputStreamDataSourceOpenCompletedKeyPath];
}

@end
