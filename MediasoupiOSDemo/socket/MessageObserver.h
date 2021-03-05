//
//  MessageObserver.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/2.
//  Copyright © 2020 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AckCallHandler)(id data);
@protocol MessageObserver <NSObject>

- (void)onMethod:(NSString *)method
   requestId:(int)requestId
notification:(BOOL)notification
        data:(NSDictionary *)data;
@end

NS_ASSUME_NONNULL_END
