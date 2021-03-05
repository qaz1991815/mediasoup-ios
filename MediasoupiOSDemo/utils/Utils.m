//
//  Utils.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/2.
//  Copyright © 2020 Location. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (NSDictionary *)deviceInfo {
    NSString *deviceName = [UIDevice currentDevice].name;
    NSString *flag = [UIDevice currentDevice].systemName;
    NSString *version = [UIDevice currentDevice].systemVersion;
    return @{
        @"name" : deviceName,
        @"flag" : flag,
        @"version" : version
    };
}

@end
