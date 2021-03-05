//
//  VideoRoomPresenter.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import "VideoRoomPresenter.h"
#import "EchoSocket.h"
#import "Request.h"
#import "RoomClient.h"
#import <mediasoup_client_ios/Mediasoupclient.h>
#import <mediasoup_client_ios/Logger.h>
#import <mediasoup_client_ios/MediasoupDevice.h>
#import "NSString+Utils.h"
#import "RendererData.h"
#import <WebRTC/WebRTC.h>
#import "NSString+Utils.h"

@interface VideoRoomPresenter () <RoomClientDelegate, EchoSocketDelegate, MessageObserver>
@property (nonatomic, strong) EchoSocket *socket;
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) RoomClient *client;
@end

@implementation VideoRoomPresenter
- (instancetype)initWithView:(UICollectionView *)view {
    self = [super init];
    if (self) {
        _collectionView = view;
        _mediadatas = [NSMutableArray array];
        RendererData *data = [[RendererData alloc] init];
        [_mediadatas addObject:data];
    }
    return self;
}

- (void)connectWebSocket {
    self.socket = [[EchoSocket alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"wss://192.168.129.121:4443?roomId=3krdth2s&peerId=%@", [NSString randomStringWithLength:7]]] registerObserver:self];
    self.socket.delegate = self;
}

- (void)webSocketDidOpen {
    [self initializeClient];

    id getRoomRtpCapabilitiesResponse = [Request sendGetRoomRtpCapabilitiesRequest:self.socket];
//    NSLog(@"getRoomRtpCapabilitiesResponse = %@", getRoomRtpCapabilitiesResponse);
    [self joinRoom:[NSString objcToJson:getRoomRtpCapabilitiesResponse]];
}
- (void)joinRoom:(NSString *)roomRtpCapabilities {
    MediasoupDevice *device = [[MediasoupDevice alloc] init];
    [device load:roomRtpCapabilities];

    self.client = [[RoomClient alloc] initWithSocket:self.socket device:device displayName:@"demo"];
    
    self.client.closed = NO;
    
    self.client.delegate = self;

    [self.client createSendTransport];

    [self.client createRecvTransport];

    [self.client join];

    [self displayLocalVideo];
}

- (void)displayLocalVideo {
    [self checkDevicePermissions];
}

- (void)checkDevicePermissions {
    
    if (![AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
                                     [self startAudio];
                                 }];
    } else {
        [self startAudio];
    }

    if (![AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     [self startVideo];
                                 }];
    } else {
        [self startVideo];
    }
}

- (void)startVideo {
    [self.client produceVideo:_mediadatas[0].videoView];
}

- (void)startAudio {
    [self.client produceAudio];
}

- (void)initializeClient {
    [Logger setLogLevel:ERROR];
    [Logger setDefaultHandler];
}

- (void)onMethod:(nonnull NSString *)method
       requestId:(int)requestId
    notification:(BOOL)notification
            data:(nonnull NSDictionary *)data {
    if ([method isEqualToString:@"newConsumer"]) {
        NSMutableDictionary *consumerIndoDic = [[NSMutableDictionary alloc] initWithDictionary:data];
        [consumerIndoDic setValue:[NSString stringWithFormat:@"%d",requestId] forKey:@"requestId"];
        [self.client consumeTrack:consumerIndoDic];
    }else if([method isEqualToString:@"newPeer"]){
        [self.client.PeersID addObject:data[@"id"]];
    }else if ([method isEqualToString:@"consumerClosed"]) {
        [self consumerClosed:[data objectForKey:@"consumerId"]];
    }
}

- (void)consumerClosed:(NSString *)consumerId {
    @try {
        for (NSInteger i = 0; i < self.client.consumersInfoVideo.count; i++) {
            NSMutableDictionary *consumerVideo = self.client.consumersInfoVideo[i];
            NSString *idV = consumerVideo[@"id"];
            if([idV isEqualToString:consumerId])
            {
                [self.client.consumersInfoVideo removeObject:consumerVideo];
                [self.client.consumersInfoAudio removeObjectAtIndex:i];
                break;
            }
        }
        [self.mediadatas enumerateObjectsUsingBlock:^(RendererData *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj.videoId isEqualToString:consumerId]) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.mediadatas removeObject:obj];
                    [self.collectionView reloadData];
                });
                *stop = YES;
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"opus");
    }
}
-(void)closeVideoCall
{
    self.client.closed = YES;
    [self.socket.socket close];
}
- (void)onNewConsumer:(nonnull Consumer *)consumer {

    RTCVideoTrack *videoTrack = (RTCVideoTrack *)[consumer getTrack];
    videoTrack.isEnabled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        RendererData *data = [[RendererData alloc] init];
        data.videoId = consumer.getId;
        [videoTrack addRenderer:data.videoView];
        [self.mediadatas addObject:data];
        [self.collectionView reloadData];
    });
}
@end
