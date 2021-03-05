//
//  EchoSocket.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/2.
//  Copyright © 2020 Location. All rights reserved.
//

#import "EchoSocket.h"
#import "NSString+Utils.h"
#import <SRWebSocket.h>

@interface EchoSocket () <SRWebSocketDelegate>
//@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<MessageObserver>> *observers;

@end

@implementation EchoSocket

- (instancetype)initWithURL:(NSURL *)url registerObserver:(id<MessageObserver>)observer {
    self = [super init];
    if (self) {
        _observers = [NSMutableDictionary dictionary];
        NSArray<NSString *> *protocols = @[ @"protoo" ];
        _socket = [[SRWebSocket alloc] initWithURL:url protocols:protocols];
        [self registerObserver:observer];
        [_socket setDelegateDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        _socket.delegate = self;
        [_socket open];
    }
    return self;
}

- (void)registerObserver:(id<MessageObserver>)observer {
    [_observers setObject:observer forKey:@([observer hash])];
}

- (void)unRegisterObserver:(id<MessageObserver>)observer {
    [_observers removeObjectForKey:@([observer hash])];
}

- (void)notifyObservers:(NSString *)method
              requestId:(int)requestId
           notification:(BOOL)notification
                   data:(id)data {
    [_observers enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull key, id<MessageObserver> _Nonnull obj, BOOL *_Nonnull stop) {
        [obj onMethod:method requestId:requestId notification:notification data:data];
    }];
}

- (void)sendResponseMsg:(NSString *)requestId {
    NSDictionary *d = @{
        @"response" : @(YES),             //默认为YES
        @"id" : @([requestId intValue]), // 随机7位数
        @"ok" : @(YES),              // 请求的名称
        @"data" : @""                    //数据体
    };
    NSString *json = [NSString objcToJson:d];
    NSLog(@"ResponseMsg：%@",json);
    [_socket send:json];
}
- (void)sendConsumerResponse:(NSString *)requestId{
    [self sendResponseMsg:requestId];
}

- (void)sendMethod:(NSString *)method
              body:(NSDictionary *)dic
         requestId:(NSString *)requestId {
    NSDictionary *d = @{
        @"request" : @(YES),             //默认为YES
        @"id" : @([requestId intValue]), // 随机7位数
        @"method" : method,              // 请求的名称
        @"data" : dic                    //数据体
    };
    NSString *json = [NSString objcToJson:d];
    [_socket send:json];
}

- (void)sendMethod:(NSString *)method
              body:(NSDictionary *)dic {
    [self sendMethod:method body:dic requestId:[NSString randomNumWithLength:7]];
}

- (void)sendWithAckMethod:(NSString *)method
                     body:(NSDictionary *)dic
        completionHandler:(AckCallHandler)completionHandler {
    dispatch_queue_t queue = dispatch_queue_create("demo", NULL);
    dispatch_async(queue, ^{
        AckCall *ackCall = [[AckCall alloc] initWithMethod:method socket:self];
        id response = [ackCall sendAckRequestBody:dic];
        completionHandler(response);
    });
}


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"socket open");
    [_delegate webSocketDidOpen];
}

- (void)webSocket:(SRWebSocket *)webSocket
    didReceiveMessage:(id)message {
    NSDictionary *response = [NSString dictionaryWithJsonString:message];
    NSString *method = [response objectForKey:@"method"];
    BOOL notification = [[response objectForKey:@"notification"] boolValue];
    NSDictionary *data = [response objectForKey:@"data"];
    int requestId = [[response objectForKey:@"id"] intValue];
    [self notifyObservers:method
                requestId:requestId
             notification:notification
                     data:data];
}

@end

@interface AckCallable () <MessageObserver>

@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) EchoSocket *socket;
@property (nonatomic, copy) AckCallHandler callback;
@property (nonatomic, strong) NSString *requestId;

@end

@implementation AckCallable

- (instancetype)initWithMethod:(NSString *)method
                     requestId:(NSString *)requestId
                        socket:(EchoSocket *)socket {
    self = [super init];
    if (self) {
        _method = method;
        _socket = socket;
        _requestId = requestId;
    }
    return self;
}

- (void)listen:(AckCallHandler)callback {
    _callback = callback;
    NSLog(@"method %@", _method);
    [self.socket registerObserver:self];
}

- (void)onMethod:(NSString *)method
       requestId:(int)requestId
    notification:(BOOL)notification
            data:(nonnull NSDictionary *)data {
    if (self.requestId.intValue == requestId) {
        self.callback(data);
        [self.socket unRegisterObserver:self];
    }
}

@end

@interface AckCall () {
    dispatch_semaphore_t _semaphor;
}

@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *requestId;

@property (nonatomic, strong) EchoSocket *socket;
@property (nonatomic, strong) id response;

@end

@implementation AckCall

- (instancetype)initWithMethod:(NSString *)method
                        socket:(EchoSocket *)socket {
    self = [super init];
    if (self) {
        _method = method;
        _socket = socket;
        _requestId = [NSString randomNumWithLength:7];
        _semaphor = dispatch_semaphore_create(0);
    }
    return self;
}

- (id)sendAckRequestBody:(NSDictionary *)body {
    [self.socket sendMethod:_method body:body requestId:_requestId];
    AckCallable *callable = [[AckCallable alloc] initWithMethod:_method requestId:_requestId socket:_socket];
    [callable listen:^(id _Nonnull data) {
        self.response = data;
        dispatch_semaphore_signal(self->_semaphor);

    }];
    dispatch_semaphore_wait(_semaphor, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)));
    return _response;
}

@end
