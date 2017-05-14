//
//  LyVideoCamera.h
//  LyAVPlayerDemo
//
//  Created by 张杰 on 2017/5/14.
//  Copyright © 2017年 张杰. All rights reserved.
//  视频采集

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface LyVideoCamera : NSObject
// 控制帧率 default:15
@property (nonatomic, assign) int frameRaw;//帧率

@property (nonatomic, assign) BOOL isVideoDataRGB;//设置屏幕渲染类型

@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;//设置屏幕方向

@property (nonatomic, assign) BOOL videoMirrored;

@property (nonatomic, assign) BOOL isCaputureAudioData;//是否包含音频数据

@property (nonatomic, copy  ) NSString *sessionPreset;//设置分辨率

@property (nonatomic, strong) void(^captureVideoSampleBufferBlcok)(CMSampleBufferRef sampleBuffer);

@property (nonatomic, strong) void(^captureAudioSampleBufferBlcok)(CMSampleBufferRef sampleBuffer);

/**
 初始化采集视频
 
 @param sessionPreset 分辨率 例如: AVCaptureSessionPreset1280x720
 @param postion 屏幕方向
 @return 对象
 */
+ (instancetype)cameraWithSessionPreset:(NSString *)sessionPreset postion:(AVCaptureDevicePosition)postion;

//开始录屏
- (void)startCapture;
//结束录屏
- (void)stopCapture;
//切换摄像头
- (void)changeScene;

@end
