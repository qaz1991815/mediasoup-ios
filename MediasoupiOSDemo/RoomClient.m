//
//  RoomClient.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import "RoomClient.h"
#import <mediasoup_client_ios/Producer.h>
#import <mediasoup_client_ios/Consumer.h>
#import <mediasoup_client_ios/MediasoupDevice.h>
#import <mediasoup_client_ios/RTCUtils.h>
#import "MediaCapture.h"
#import "Request.h"
#import "Utils.h"
#import "NSString+Utils.h"
#import <AVFoundation/AVFoundation.h>

@interface SendTransportHandler : NSObject <SendTransportListener>
@property (nonatomic, strong) RoomClient *parent;
@end

@implementation SendTransportHandler

- (instancetype)initWithParent:(RoomClient *)parent {
    self = [super init];
    if (self) {
        _parent = parent;
    }
    return self;
}

- (void)onConnect:(Transport *)transport dtlsParameters:(NSString *)dtlsParameters {
    [self.parent handleLocalTransportConnectEvent:transport dtlsParameters:dtlsParameters];
}

- (void)onConnectionStateChange:(Transport *)transport connectionState:(NSString *)connectionState {
    NSLog(@"SendTransportHandler:%@",connectionState);
    NSLog(@"SendTransportHandler:%d",transport.isClosed);
    if([connectionState isEqualToString:@"disconnected"] && self.parent.closed)
    {
        [transport close];
    }
}

- (void)onProduce:(Transport *)transport kind:(NSString *)kind rtpParameters:(NSString *)rtpParameters appData:(NSString *)appData callback:(void (^)(NSString *))callback {
    callback([self.parent handleLocalTransportProduceEvent:transport kind:kind rtpParameters:rtpParameters appData:appData]);
}

@end

@interface RecvTransportHandler : NSObject <RecvTransportListener>
@property (nonatomic, strong) RoomClient *parent;
@end

@implementation RecvTransportHandler

- (instancetype)initWithParent:(RoomClient *)parent {
    self = [super init];
    if (self) {
        _parent = parent;
    }
    return self;
}

- (void)onConnect:(Transport *)transport dtlsParameters:(NSString *)dtlsParameters {
    [self.parent handleLocalTransportConnectEvent:transport
                                   dtlsParameters:dtlsParameters];
}

- (void)onConnectionStateChange:(Transport *)transport connectionState:(NSString *)connectionState {
    NSLog(@"RecvTransportHandler:%@",connectionState);
    NSLog(@"RecvTransportHandler:%d",transport.isClosed);
    if([connectionState isEqualToString:@"disconnected"] && self.parent.closed)
    {
        [transport close];
    }
}

@end

@interface ProducerHandler : NSObject <ProducerListener>

@end

@implementation ProducerHandler

- (void)onTransportClose:(Producer *)producer {
    NSLog(@"Producer::onTransportClose");
}

@end

@interface ConsumerHandler : NSObject <ConsumerListener>

@end

@implementation ConsumerHandler

- (void)onTransportClose:(Consumer *)consumer {
    NSLog(@"Consumer::onTransportClose");
}

@end

@interface RoomClient ()
@property (nonatomic, strong) EchoSocket *socket;
@property (nonatomic, strong) MediaCapture *mediaCapture;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Producer *> *producers;


@property (nonatomic, strong) MediasoupDevice *device;

@property (nonatomic, assign) BOOL joined;

@property (nonatomic, strong) SendTransport *sendTransport;
@property (nonatomic, strong) RecvTransport *recvTransport;

@property (nonatomic, strong) NSString *displayName;

@property (nonatomic, strong) SendTransportHandler *sendTransportHandler;
@property (nonatomic, strong) RecvTransportHandler *recvTransportHandler;

@property (nonatomic, strong) ProducerHandler *producerHandler;
@property (nonatomic, strong) ConsumerHandler *consumerHandler;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *kind;
@property (nonatomic, strong) NSString *producerId;
@property (nonatomic, strong) NSDictionary *rtpParameters;

@property (nonatomic, strong) dispatch_semaphore_t sema;

@end

@implementation RoomClient

- (instancetype)initWithSocket:(EchoSocket *)socket device:(MediasoupDevice *)device displayName:(NSString *)displayName {
    self = [super init];
    if (self) {
        _socket = socket;
        _device = device;
        _mediaCapture = [[MediaCapture alloc] init];

        _producers = [NSMutableDictionary dictionary];
        _consumers = [NSMutableDictionary dictionary];
        _consumersInfoAudio = [NSMutableArray array];
        _consumersInfoVideo = [NSMutableArray array];
        _PeersID = [NSMutableArray array];
        _sema = dispatch_semaphore_create(0);
        _joined = NO;
        _displayName = displayName;
    }
    return self;
}

- (void)join {
    if (!self.device.isLoaded) {
        return;
    }
    if (self.joined) {
        return;
    }
    id response = [Request sendLoginRoomRequest:_socket
                                    displayName:_displayName
                                         device:[Utils deviceInfo]
                          deviceRtpCapabilities:[NSString dictionaryWithJsonString:self.device.getRtpCapabilities]];
    self.joined = YES;
    NSLog(@"join() join success:%@",response);
}

- (void)createSendTransport {
    if (self.sendTransport != nil) {
        return;
    }
    [self createWebRtcTransport:@"send"];
}

- (void)createRecvTransport {
    if (self.recvTransport != nil) {
        return;
    }
    [self createWebRtcTransport:@"recv"];
}



- (void)createWebRtcTransport:(NSString *)direction {
    id response = [Request sendCreateWebRTCTransportRequest:_socket direction:direction];
    NSString *idString = [response objectForKey:@"id"];
    NSString *iceParameters = [NSString objcToJson:[response objectForKey:@"iceParameters"]];
    NSString *iceCandidatesArray = [NSString objcToJson:[response objectForKey:@"iceCandidates"]];
    NSString *dtlsParameters = [NSString objcToJson:[response objectForKey:@"dtlsParameters"]];

    if ([direction isEqualToString:@"send"]) {
        self.sendTransportHandler = [[SendTransportHandler alloc] initWithParent:self];
        self.sendTransport = [self.device createSendTransport:self.sendTransportHandler id:idString iceParameters:iceParameters iceCandidates:iceCandidatesArray dtlsParameters:dtlsParameters];

    } else if ([direction isEqualToString:@"recv"]) {
        self.recvTransportHandler = [[RecvTransportHandler alloc] initWithParent:self];
        self.recvTransport = [self.device createRecvTransport:self.recvTransportHandler id:idString iceParameters:iceParameters iceCandidates:iceCandidatesArray dtlsParameters:dtlsParameters];
    }
}

- (void)createProducer:(RTCMediaStreamTrack *)track
          codecOptions:(NSString *)codecOptions
             encodings:(NSArray<RTCRtpEncodingParameters *> *)encodings {
    self.producerHandler = [[ProducerHandler alloc] init];
    Producer *kindProducer = [self.sendTransport produce:self.producerHandler
                                                   track:track
                                               encodings:encodings
                                            codecOptions:codecOptions];
    [self.producers setObject:kindProducer forKey:kindProducer.getId];
}

- (RTCVideoTrack *)produceVideo:(RTCEAGLVideoView *)videoView {
    if (self.sendTransport == NULL) {
        NSLog(@"transport nil");
        return NULL;
    }

    if (![self.device canProduce:@"video"]) {
        NSLog(@"cannot produce");
        return NULL;
    }

    RTCVideoTrack *videoTrack = [self.mediaCapture createVideoTrack:videoView];
    NSDictionary *codecOptions = @{ @"videoGoogleStartBitrate" : @1000 };
    [self createProducer:videoTrack codecOptions:[NSString objcToJson:codecOptions] encodings:nil];
    [self createConsumerAndResume];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeVideoChat options:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    return videoTrack;
}

- (void)produceAudio {
    RTCAudioTrack *audioTrack = [self.mediaCapture createAudioTrack];
    [self createProducer:audioTrack codecOptions:nil encodings:nil];
}
- (void)handleLocalTransportConnectEvent:(Transport *)transport dtlsParameters:(NSString *)dtlsParameters {
    [Request sendConnectWebRTCTransportRequest:_socket transportId:[transport getId] dtlsParameters:[NSString dictionaryWithJsonString:dtlsParameters]];
}

- (NSString *)handleLocalTransportProduceEvent:(Transport *)transport
                                          kind:(NSString *)kind
                                 rtpParameters:(NSString *)rtpParameters
                                       appData:(NSString *)appData {
    id data = [Request sendProduceWebRTCTransportRequest:self.socket
                                             transportId:transport.getId
                                                    kind:kind
                                           rtpParameters:[NSString dictionaryWithJsonString:rtpParameters]];
    return [data objectForKey:@"id"];
}
- (void)sendResponse:(NSString *)requestId
{
    [Request sendResponset:_socket requestId:requestId];
}
- (void)createConsumerAndResume
{
    @try {
        self.consumerHandler = [[ConsumerHandler alloc] init];
        for (NSInteger i = 0; i < self.consumersInfoAudio.count; i++) {
            
            NSMutableDictionary *consumerAudio = self.consumersInfoAudio[i];
            NSString *requestIdA = consumerAudio[@"requestId"];
            NSString *kindA = consumerAudio[@"kind"];
            NSString *idA = consumerAudio[@"id"];
            NSString *producerIdA = consumerAudio[@"producerId"];
            NSDictionary *rtpParametersA = consumerAudio[@"rtpParameters"];
            
            NSMutableDictionary *consumerVideo = self.consumersInfoVideo[i];
            NSString *requestIdV = consumerVideo[@"requestId"];
            NSString *kindV = consumerVideo[@"kind"];
            NSString *idV = consumerVideo[@"id"];
            NSString *producerIdV = consumerVideo[@"producerId"];
            NSDictionary *rtpParametersV = consumerVideo[@"rtpParameters"];
            
            dispatch_queue_t testqueue = dispatch_queue_create("queue2021", NULL);
            dispatch_sync(testqueue, ^{
                @synchronized(self) {
                    Consumer *kindConsumer = [self.recvTransport consume:self.consumerHandler id:idA producerId:producerIdA kind:kindA rtpParameters:[NSString objcToJson:rtpParametersA]];
                    [self.consumers setObject:kindConsumer forKey:[kindConsumer getId]];
                }
            });
            
            dispatch_sync(testqueue, ^{
                @synchronized(self) {
                    [self sendResponse:requestIdA];
                }
            });
            
            dispatch_sync(testqueue, ^{
                @synchronized(self) {
                    Consumer *kindConsumer = [self.recvTransport consume:self.consumerHandler id:idV producerId:producerIdV kind:kindV rtpParameters:[NSString objcToJson:rtpParametersV]];
                    [self.consumers setObject:kindConsumer forKey:[kindConsumer getId]];
                    [_delegate onNewConsumer:kindConsumer];
                }
            });
            
            dispatch_sync(testqueue, ^{
                @synchronized(self) {
                    [self sendResponse:requestIdV];
                }
            });
        }
    } @catch (NSException *exception) {
        NSLog(@"oups");
    }
}
- (void)consumeTrack:(NSMutableDictionary *)consumerInfo {
    NSString *kind = [consumerInfo objectForKey:@"kind"];
    if([kind isEqualToString:@"audio"])
    {
        [self.consumersInfoAudio addObject:consumerInfo];
    }
    else
    {
        [self.consumersInfoVideo addObject:consumerInfo];
    }
    if(self.PeersID.count != 0)
    {
        NSString *requestId = [consumerInfo objectForKey:@"requestId"];
        NSString *kind = [consumerInfo objectForKey:@"kind"];
        NSString *id = [consumerInfo objectForKey:@"id"];
        NSString *producerId = [consumerInfo objectForKey:@"producerId"];
        NSDictionary *rtpParameters = [consumerInfo objectForKey:@"rtpParameters"];
        
        Consumer *kindConsumer = [self.recvTransport consume:self.consumerHandler id:id producerId:producerId kind:kind rtpParameters:[NSString objcToJson:rtpParameters]];
        [self.consumers setObject:kindConsumer forKey:[kindConsumer getId]];
        if([kind isEqualToString:@"video"])
        {
            [_delegate onNewConsumer:kindConsumer];
        }
        [self sendResponse:requestId];
    }
}

@end
