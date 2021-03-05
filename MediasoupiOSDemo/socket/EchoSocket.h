//
//  EchoSocket.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/2.
//  Copyright © 2020 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MessageObserver.h"
#import <SRWebSocket.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EchoSocketDelegate <NSObject>

- (void)webSocketDidOpen;

@end

@interface EchoSocket : NSObject

@property (nonatomic, weak) id<EchoSocketDelegate> delegate;

@property (nonatomic, strong) SRWebSocket *socket;

- (instancetype)initWithURL:(NSURL *)url
           registerObserver:(id<MessageObserver>)observer;

- (void)registerObserver:(id<MessageObserver>)observer;

- (void)unRegisterObserver:(id<MessageObserver>)observer;

- (void)sendMethod:(NSString *)method
              body:(NSDictionary *)dic;

- (void)sendMethod:(NSString *)method
              body:(NSDictionary *)dic
         requestId:(NSString *)raequestId;

- (void)sendWithAckMethod:(NSString *)method
                     body:(NSDictionary *)dic
        completionHandler:(AckCallHandler)completionHandler;

- (void)sendConsumerResponse:(NSString *)requestId;

@end

@interface AckCall : NSObject

@property (nonatomic, copy) AckCallHandler handler;

- (instancetype)initWithMethod:(NSString *)method
                        socket:(EchoSocket *)socket;
- (id)sendAckRequestBody:(NSDictionary *)body;

@end

@interface AckCallable : NSObject
@end

NS_ASSUME_NONNULL_END
