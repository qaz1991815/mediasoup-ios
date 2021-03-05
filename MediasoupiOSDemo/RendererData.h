//
//  RendererData.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RTCEAGLVideoView;
NS_ASSUME_NONNULL_BEGIN

@interface RendererData : NSObject
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) RTCEAGLVideoView *videoView;
@end

NS_ASSUME_NONNULL_END
