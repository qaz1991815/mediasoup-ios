 
        
    
//
//  MediaCapture.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import "MediaCapture.h"
#import <WebRTC/WebRTC.h>

static NSString *const KARDMediaStreamId = @"ARDAMS";
static NSString *const KARDAudioTrackId = @"ARDAMSa0";
static NSString *const KARDVideoTrackId = @"ARDAMSv0";

@interface MediaCapture () <RTCVideoCapturerDelegate>
@property (nonatomic, strong) RTCPeerConnectionFactory *peerConnectionFactory;

@property (nonatomic, strong) RTCMediaStream *mediaStream;
@property (nonatomic, strong) RTCCameraVideoCapturer *videoCapture;
@property (nonatomic, strong) RTCVideoSource *videoSource;

@end

@implementation MediaCapture

- (instancetype)init {
    self = [super init];
    if (self) {
        _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
        _mediaStream = [_peerConnectionFactory mediaStreamWithStreamId:KARDMediaStreamId];
    }
    return self;
}

- (RTCVideoTrack *)createVideoTrack:(RTCEAGLVideoView *)videoView {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;

    if (captureDevices.count > 0) {
        AVCaptureDevice *device = captureDevices[0];
        for (AVCaptureDevice *obj in captureDevices) {
            if (obj.position == position) {
                device = obj;
                break;
            }
        }

        if (device) {
            RTCVideoSource *videoSource = [_peerConnectionFactory videoSource];
            [videoSource adaptOutputFormatToWidth:144 height:192 fps:30];

            _videoCapture = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];

            AVCaptureDeviceFormat *format = [[RTCCameraVideoCapturer supportedFormatsForDevice:device] lastObject];

            CGFloat fps = [[format videoSupportedFrameRateRanges] firstObject].maxFrameRate;

            [_videoCapture startCaptureWithDevice:device format:format fps:fps];

            RTCVideoTrack *videoTrack = [_peerConnectionFactory videoTrackWithSource:videoSource trackId:KARDVideoTrackId];
            [self.mediaStream addVideoTrack:videoTrack];

            videoTrack.isEnabled = YES;
            [videoTrack addRenderer:videoView];
            return videoTrack;
        }
    }
    return NULL;
}

- (RTCAudioTrack *)createAudioTrack {
    RTCAudioTrack *audioTrack = [_peerConnectionFactory audioTrackWithTrackId:KARDAudioTrackId];
    audioTrack.isEnabled = YES;
    [self.mediaStream addAudioTrack:audioTrack];
    return audioTrack;
}

- (void)capturer:(RTCVideoCapturer *)capturer
didCaptureVideoFrame:(RTCVideoFrame *)frame {
    [self.videoSource capturer:capturer didCaptureVideoFrame:frame];
}

@end
