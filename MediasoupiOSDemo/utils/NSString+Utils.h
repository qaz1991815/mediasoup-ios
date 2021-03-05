//
//  NSString+Utils.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/2.
//  Copyright © 2020 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Utils)
+ (NSString *)randomStringWithLength:(int)len;

+ (NSString *)randomNumWithLength:(int)len;

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

+ (NSString *)objcToJson:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
