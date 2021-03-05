//
//  Request.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import "Request.h"

@implementation Request
+ (id)sendGetRoomRtpCapabilitiesRequest:(EchoSocket *)socket {
    return [Request sendSocketAckRequest:socket method:@"getRouterRtpCapabilities" body:@{}];
}

+ (id)sendLoginRoomRequest:(EchoSocket *)socket
               displayName:(NSString *)displayName
                    device:(NSDictionary *)device
     deviceRtpCapabilities:(NSDictionary *)deviceRtpCapabilities {
    return [Request sendSocketAckRequest:socket
                                  method:@"join"
                                    body:@{
                                        @"displayName" : displayName,
                                        @"device" : device,
                                        @"rtpCapabilities" : deviceRtpCapabilities
                                    }];
}

+ (id)sendCreateWebRTCTransportRequest:(EchoSocket *)socket
                             direction:(NSString *)direction {
    return [Request sendSocketAckRequest:socket
                                  method:@"createWebRtcTransport"
                                    body:@{
                                        @"forceTcp" : @(NO),
                                        @"producing" : [direction isEqualToString:@"send"] ? @(YES) : @(NO),
                                        @"consuming" : [direction isEqualToString:@"send"] ? @(NO) : @(YES),
                                    }];
}

+ (void)sendConnectWebRTCTransportRequest:(EchoSocket *)socket
                              transportId:(NSString *)transportId
                           dtlsParameters:(NSDictionary *)dtlsParameters {
    [socket sendMethod:@"connectWebRtcTransport"
                  body:@{
                      @"transportId" : transportId,
                      @"dtlsParameters" : dtlsParameters
                  }];
}

+ (id)sendProduceWebRTCTransportRequest:(EchoSocket *)socket
                            transportId:(NSString *)transportId
                                   kind:(NSString *)kind
                          rtpParameters:(NSDictionary *)rtpParameters {

    return [Request sendSocketAckRequest:socket
                                  method:@"produce"
                                    body:@{
                                        @"transportId" : transportId,
                                        @"kind" : kind,
                                        @"rtpParameters" : rtpParameters
                                    }];
}
+ (void)sendResponset:(EchoSocket *)socket
            requestId:(NSString *)requestId {
    [socket sendConsumerResponse:requestId];
}
+ (id)sendSocketAckRequest:(EchoSocket *)socket
                    method:(NSString *)method
                      body:(NSDictionary *)body {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id response = NULL;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(quene, ^{
        [socket sendWithAckMethod:method
                             body:body
                completionHandler:^(id _Nonnull data) {
                    response = data;
                    dispatch_semaphore_signal(semaphore);
                }];
    });

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)));
    return response;
}
@end
