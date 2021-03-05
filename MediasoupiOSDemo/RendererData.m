//
//  RendererData.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import "RendererData.h"
#import <WebRTC/WebRTC.h>
@implementation RendererData
- (instancetype)init {
    self = [super init];
    if (self) {
        _videoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0, 144, 192)];
        
    }
    return self;
}
@end
