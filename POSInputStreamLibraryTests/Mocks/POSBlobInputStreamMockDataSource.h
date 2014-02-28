//
//  POSBlobInputStreamMockDataSource.h
//  POSBlobInputStreamTests
//
//  Created by Pavel Osipov on 16.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import "POSBlobInputStreamDataSource.h"

@interface POSBlobInputStreamMockDataSource : NSObject <POSBlobInputStreamDataSource>

- (id)initWithLength:(long long)length;
- (id)initWithOpenError:(NSError *)error;

@end
