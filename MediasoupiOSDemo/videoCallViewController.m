//
//  videoCallViewController.m
//  MediasoupiOSDemo
//
//  Created by HX on 2021/2/25.
//  Copyright © 2021 Location. All rights reserved.
//

#import "videoCallViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoRoomPresenter.h"

#import "RendererData.h"
#import "MediaViewCell.h"
#import "VideoRoomPresenter.h"
#import "RendererData.h"
@interface videoCallViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) VideoRoomPresenter *presenter;
@property (nonatomic, strong) UIButton *startOrclose;
@property (nonatomic, strong) UIButton *resumeMedia;
@property (nonatomic, strong) UIButton *backBtn;

@end

@implementation videoCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.groupTableViewBackgroundColor;
    
    UICollectionViewFlowLayout *layOut = [[UICollectionViewFlowLayout alloc] init];
    CGFloat w = self.view.frame.size.width / 2 - 1;
    layOut.itemSize = CGSizeMake(w, w / 0.75);

    layOut.sectionInset = UIEdgeInsetsMake(0, 0, 1, 0);

    layOut.minimumLineSpacing = 1;

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 250) collectionViewLayout:layOut];

    _collectionView.pagingEnabled = YES;

    _collectionView.backgroundColor = [UIColor clearColor];

    [_collectionView registerClass:[MediaViewCell class] forCellWithReuseIdentifier:@"MediaViewCell"];

    _collectionView.semanticContentAttribute = UISemanticContentAttributeSpatial;

    _collectionView.delegate = self;

    _collectionView.dataSource = self;

    [self.view addSubview:_collectionView];

    _presenter = [[VideoRoomPresenter alloc] initWithView:_collectionView];
    [_presenter connectWebSocket];
    
    _startOrclose = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height - 150, 100, 100)];
    [_startOrclose setTitle:@"endCall" forState:UIControlStateNormal];
    [_startOrclose setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_startOrclose addTarget:self action:@selector(closeVideoCall) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startOrclose];
    // Do any additional setup after loading the view.
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _presenter.mediadatas.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MediaViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaViewCell" forIndexPath:indexPath];

    RendererData *data = _presenter.mediadatas[indexPath.row];

    [cell addMediaView:(UIView *)data.videoView];

    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row != 0)
    {
        RendererData *data = _presenter.mediadatas[indexPath.row];
        NSLog(@"%@",data.videoId);
    }
}
-(void)closeVideoCall
{
    [self.presenter closeVideoCall];
    [self dismissViewControllerAnimated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
