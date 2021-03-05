//
//  Request.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EchoSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface Request : NSObject

+ (id)sendGetRoomRtpCapabilitiesRequest:(EchoSocket *)socket;

+ (id)sendLoginRoomRequest:(EchoSocket *)socket
               displayName:(NSString *)displayName
                    device:(NSDictionary *)device
     deviceRtpCapabilities:(NSDictionary *)deviceRtpCapabilities;

+ (id)sendCreateWebRTCTransportRequest:(EchoSocket *)socket
                             direction:(NSString *)direction;

+ (void)sendConnectWebRTCTransportRequest:(EchoSocket *)socket
                              transportId:(NSString *)transportId
                           dtlsParameters:(NSDictionary *)dtlsParameters;

+ (id)sendProduceWebRTCTransportRequest:(EchoSocket *)socket
                            transportId:(NSString *)transportId
                                   kind:(NSString *)kind
                          rtpParameters:(NSDictionary *)rtpParameters;
+ (void)sendResponset:(EchoSocket *)socket
            requestId:(NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
