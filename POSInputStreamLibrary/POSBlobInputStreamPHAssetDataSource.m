//
//  POSBlobInputStreamPHAssetDataSource.m
//  POSInputStreamLibrary
//
//  Created by Pavel Osipov on 07.12.15.
//  Copyright © 2015 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamPHAssetDataSource.h"
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
    /// TODO: Add implementation.
}

@end
