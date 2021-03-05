//
//  MediaCapture.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RTCVideoTrack;
@class RTCAudioTrack;
@class RTCEAGLVideoView;

NS_ASSUME_NONNULL_BEGIN

@interface MediaCapture : NSObject
- (RTCVideoTrack *)createVideoTrack:(RTCEAGLVideoView *)videoView;

- (RTCAudioTrack *)createAudioTrack;
@end

NS_ASSUME_NONNULL_END
