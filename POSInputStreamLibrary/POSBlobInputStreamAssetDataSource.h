//
//  POSBlobInputStreamAssetDataSource.h
//  POSBlobInputStreamLibrary
//
//  Created by Pavel Osipov on 16.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamDataSource.h"
#import <AssetsLibrary/AssetsLibrary.h>

FOUNDATION_EXTERN NSString * const POSBlobInputStreamAssetDataSourceErrorDomain;

typedef NS_ENUM(NSInteger, POSBlobInputStreamAssetDataSourceErrorCode) {
    POSBlobInputStreamAssetDataSourceErrorCodeOpen = 0,
    POSBlobInputStreamAssetDataSourceErrorCodeRead = 1
};

@interface POSBlobInputStreamAssetDataSource : NSObject <POSBlobInputStreamDataSource>

@property (nonatomic, assign, getter = shouldOpenSynchronously) BOOL openSynchronously;

- (id)initWithAssetURL:(NSURL *)assetURL;

@end
