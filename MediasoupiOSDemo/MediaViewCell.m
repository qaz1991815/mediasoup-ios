//
//  MediaViewCell.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import "MediaViewCell.h"

@implementation MediaViewCell
- (void)addMediaView:(UIView *)view {
    [view removeFromSuperview];
    CGSize size = self.frame.size;
    view.frame = CGRectMake(0, 0, size.width, size.height);
    [self addSubview:view];
}
@end
