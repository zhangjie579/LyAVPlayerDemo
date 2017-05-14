//
//  LyGPUImage.m
//  LyAVPlayerDemo
//
//  Created by 张杰 on 2017/5/14.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "LyGPUImage.h"
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"

@interface LyGPUImage ()

@property (nonatomic, strong) GPUImageVideoCamera *camera;//创建视频源

@end

/*  步骤
 1.创建视频源
 2.创建滤镜,处理图片
 3.将美颜效果，输出连接起来
 4.得到图片
 */

@implementation LyGPUImage

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)dealwithImage
{
    //1.创建视频源
    
    //2.创建滤镜,处理图片
    // 创建滤镜
    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    //    // 美白滤镜
    //    GPUImageBrightnessFilter *filter = [[GPUImageBrightnessFilter alloc] init];
    //    filter.brightness = 0.3;
    //
    //    // 磨皮滤镜
    //    GPUImageBilateralFilter *bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    //    // 值越小,磨皮效果越明显
    //    bilateralFilter.distanceNormalizationFactor = 5;
    
    //3.创建最终目的
    GPUImageView *preview = [[GPUImageView alloc] initWithFrame:self.bounds];
    [self insertSubview:preview atIndex:0];
    
//    // 怎么处理GPUImage返回数据
//    GPUImageRawDataOutput *rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:self.bounds.size resultsInBGRAFormat:NO];
//
//    __weak typeof(GPUImageRawDataOutput) *weakRawDataOutput = rawDataOutput;
//
//    rawDataOutput.newFrameAvailableBlock = ^{
//
//        NSLog(@"%s",weakRawDataOutput.rawBytesForImage);
//        NSLog(@"处理完一帧就会调用");
//
//    };
    
    //4.添加处理链
    [self.camera addTarget:beautifyFilter];
    
    // 输出屏幕显示
    [beautifyFilter addTarget:preview];
    
    //    [filter addTarget:bilateralFilter];
    // 输出数据
    //    [bilateralFilter addTarget:rawDataOutput];
    
    // 开始捕获
    [self.camera startCameraCapture];
    
}

//旋转
- (void)rotation
{
    [self.camera rotateCamera];
}

- (void)stop
{
    //结束
    [self.camera stopCameraCapture];
}

//创建视频源
- (GPUImageVideoCamera *)camera
{
    if (!_camera) {
        //分辨率;摄像头的位置
        _camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        //屏幕方向
        _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    }
    return _camera;
}

@end
