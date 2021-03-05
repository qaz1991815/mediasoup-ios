//
//  RoomClient.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Transport;
@class EchoSocket;
@class MediasoupDevice;
@class RTCEAGLVideoView;
@class RTCVideoTrack;
@class Consumer;

NS_ASSUME_NONNULL_BEGIN

@protocol RoomClientDelegate <NSObject>
- (void)onNewConsumer:(Consumer *)consumer;
@end

@interface RoomClient : NSObject
@property (nonatomic, strong) NSMutableArray *consumersInfoAudio;
@property (nonatomic, strong) NSMutableArray *consumersInfoVideo;
@property (nonatomic, strong) NSMutableArray *PeersID;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Consumer *> *consumers;
@property (nonatomic, assign) BOOL closed;

@property (nonatomic, weak) id<RoomClientDelegate> delegate;
- (instancetype)initWithSocket:(EchoSocket *)socket
                        device:(MediasoupDevice *)device
                   displayName:(NSString *)displayName;

- (void)join;

- (void)createSendTransport;

- (void)createRecvTransport;

- (RTCVideoTrack *)produceVideo:(RTCEAGLVideoView *)videoView;

- (void)produceAudio;

- (void)consumeTrack:(NSDictionary *)consumerInfo;

- (void)handleLocalTransportConnectEvent:(Transport *)transport
                          dtlsParameters:(NSString *)dtlsParameters;

- (NSString *)handleLocalTransportProduceEvent:(Transport *)transport
                                          kind:(NSString *)kind
                                 rtpParameters:(NSString *)rtpParameters
                                       appData:(NSString *)appData;

- (void)sendResponse:(NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
