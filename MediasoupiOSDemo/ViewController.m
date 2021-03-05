//
//  ViewController.m
//  MediasoupiOSDemo
//
//  Created by hello on 2020/4/2.
//  Copyright © 2020 Location. All rights reserved.
//
#import "ViewController.h"
#import "videoCallViewController.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *startOrclose;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _startOrclose = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, self.view.frame.size.height/2 - 100, 200, 200)];
    [_startOrclose setTitle:@"开始通话" forState:UIControlStateNormal];
    [_startOrclose setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_startOrclose addTarget:self action:@selector(startVideoCall) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startOrclose];

}
-(void)startVideoCall
{
    videoCallViewController *VC = [[videoCallViewController alloc] init];
    VC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:VC animated:YES completion:nil];
}
@end
