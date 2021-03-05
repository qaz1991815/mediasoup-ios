//
//  VideoRoomPresenter.h
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/3.
//  Copyright © 2020 Location. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class RendererData;
@interface VideoRoomPresenter : NSObject
@property (nonatomic, strong) NSMutableArray<RendererData *> *mediadatas;

- (instancetype)initWithView:(UICollectionView *)view;
- (void)connectWebSocket;
- (void)closeVideoCall;

@end

NS_ASSUME_NONNULL_END
