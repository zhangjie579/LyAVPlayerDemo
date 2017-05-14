//
//  LyViewController.m
//  LyAVPlayerDemo
//
//  Created by 张杰 on 2017/5/14.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "LyViewController.h"
#import "LyOpenGLView.h"
#import "LyVideoCamera.h"

@interface LyViewController ()

@property(nonatomic,strong)LyOpenGLView  *openGLView;
@property(nonatomic,strong)LyVideoCamera *videoCamera;

@end

@implementation LyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.openGLView];
    
    __weak typeof(self) weakSelf = self;
    
    self.videoCamera.captureVideoSampleBufferBlcok = ^(CMSampleBufferRef sampleBuffer) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.openGLView displayWithSampleBuffer:sampleBuffer];
        
    };
    
    //开始捕获视频
    [self.videoCamera startCapture];
}

- (LyOpenGLView *)openGLView
{
    if (!_openGLView) {
        _openGLView = [[LyOpenGLView alloc] init];
        _openGLView.frame = self.view.bounds;
    }
    return _openGLView;
}

- (LyVideoCamera *)videoCamera
{
    if (!_videoCamera) {
        _videoCamera = [LyVideoCamera cameraWithSessionPreset:AVCaptureSessionPreset1280x720 postion:AVCaptureDevicePositionFront];
        _videoCamera.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    return _videoCamera;
}

@end
