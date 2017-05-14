//
//  LyVideoCamera.m
//  LyAVPlayerDemo
//
//  Created by 张杰 on 2017/5/14.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "LyVideoCamera.h"

@interface LyVideoCamera ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession          *session;//会话
@property (nonatomic, strong) AVCaptureVideoDataOutput  *videoOutput;//视频输出
@property (nonatomic, strong) AVCaptureDeviceInput      *videoInput;//视频输入
@property (nonatomic, strong) AVCaptureMovieFileOutput  *movieOutput;//写入沙盒
@property (nonatomic, weak  ) AVCaptureDevice           *videoDevice;//视频设备
@property (nonatomic, weak  ) AVCaptureConnection       *videoConnection;//视频连接

@end

@implementation LyVideoCamera

/**
 初始化采集视频

 @param sessionPreset 分辨率 例如: AVCaptureSessionPreset1280x720
 @param postion 屏幕方向
 @return 对象
 */
+ (instancetype)cameraWithSessionPreset:(NSString *)sessionPreset postion:(AVCaptureDevicePosition)postion
{
    LyVideoCamera *camera = [[LyVideoCamera alloc] init];
    
    //0.设置会话
    camera.sessionPreset = sessionPreset;
    
    //1.捕获视频数据
    [camera captureVideo:postion];
    
    return camera;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.videoMirrored = YES;
        self.videoOrientation = AVCaptureVideoOrientationPortrait;
        self.frameRaw = 15;
        self.isVideoDataRGB = NO;
    }
    return self;
}

//设置分辨率
- (void)setSessionPreset:(NSString *)sessionPreset
{
    _sessionPreset = [sessionPreset copy];
    
    if (sessionPreset.length == 0) {
        sessionPreset = AVCaptureSessionPresetHigh;
    }
    self.session.sessionPreset = sessionPreset;
}

//是否包含音频
- (void)setIsCaputureAudioData:(BOOL)isCaputureAudioData
{
    _isCaputureAudioData = isCaputureAudioData;
    
    if (isCaputureAudioData) {
        //2.捕获音频数据
        [self captureAudio];
    }
}

//最小帧率
- (void)setFrameRaw:(int)frameRaw
{
    _frameRaw = frameRaw;
    
    self.videoOutput.minFrameDuration = CMTimeMake(1, frameRaw);
    self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, frameRaw);
}

//设置屏幕渲染类型
- (void)setIsVideoDataRGB:(BOOL)isVideoDataRGB
{
    _isVideoDataRGB = isVideoDataRGB;
    
    NSString *dataFmt = nil;
    
    if (_isVideoDataRGB) {
        dataFmt = @(kCVPixelFormatType_32BGRA);
    } else {
        dataFmt = @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    }
    
    //设置视频格式
    self.videoOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:dataFmt};
}

//设置屏幕方向
- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    _videoOrientation = videoOrientation;
    
    self.videoConnection.videoOrientation = self.videoOrientation;
}

- (void)setVideoMirrored:(BOOL)videoMirrored
{
    _videoMirrored = videoMirrored;
    
    self.videoConnection.videoMirrored = videoMirrored;
}

//开始录屏
- (void)startCapture
{
    [self.session startRunning];
}

//结束录屏
- (void)stopCapture
{
    [self.session stopRunning];
}

//切换摄像头
- (void)changeScene
{
    //1.获取当前摄像头的方向
    AVCaptureDevicePosition position = self.videoInput.device.position;
    
    //2.切换方向
    position = position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    
    //3.根据新的方向创建device
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:position];
    
    //4.创建新的输入
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    
    //5.在session中切换
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    if ([self.session canAddInput:videoInput]) {
        [self.session addInput:videoInput];
    }
    [self.session commitConfiguration];
    
    //6.将新的输入赋值给全局变量
    self.videoInput = videoInput;
}

#pragma mark - private

#pragma mark - 音频
//捕获音频数据
- (void)captureAudio
{
    //1.获取设备
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //2.输入
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
    
    //3.输出
    // 音频格式PCM
    // 对应音频输出,音频输入必须对应音频输出
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    //4.添加到会话
    if ([self.session canAddInput:audioInput]) {
        [self.session addInput:audioInput];
    }
    
    if ([self.session canAddOutput:audioOutput]) {
        [self.session addOutput:audioOutput];
    }
    
    //5.设置delegate
    dispatch_queue_t audioQueue = dispatch_queue_create("audioQueue", DISPATCH_QUEUE_SERIAL);
    [audioOutput setSampleBufferDelegate:self queue:audioQueue];
}

#pragma mark - 视频
//捕获视频数据
- (void)captureVideo:(AVCaptureDevicePosition)postion
{
    //1.获取前置摄像头照相机
    AVCaptureDevice *videoDevice = [self videoDeviceWithPostion:postion];
    videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, self.frameRaw);
    self.videoDevice = videoDevice;
    
    //2.设置输入
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    self.videoInput = videoInput;
    
    //3.设置输出
    //    AVCaptureVideoDataOutput
    
    //4.将输入添加到会话
    if ([self.session canAddInput:videoInput]) {
        [self.session addInput:videoInput];
    }
    
    //5.添加输出到会话
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
    //6.获取连接
    // 只要给会话添加输入和输出就会自动创建连接
    AVCaptureConnection *videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 设置竖屏
    videoConnection.videoOrientation = self.videoOrientation;
    videoConnection.automaticallyAdjustsVideoMirroring = NO;
    videoConnection.videoMirrored = self.videoMirrored;
//    videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
//    videoConnection.automaticallyAdjustsVideoMirroring = NO;
//    videoConnection.videoMirrored = YES;
    self.videoConnection = videoConnection;
}

// 指定一个摄像头方向,获取对应摄像设备
- (AVCaptureDevice *)videoDeviceWithPostion:(AVCaptureDevicePosition)positon
{
    // defaultDeviceWithMediaType获取后置摄像头
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == positon) {
            return device;
        }
    }
    return nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (_videoOutput == captureOutput) { // 视频
        if (_captureVideoSampleBufferBlcok) {
            _captureVideoSampleBufferBlcok(sampleBuffer);
        }
        
    } else { // 音频
        if (_captureAudioSampleBufferBlcok) {
            _captureAudioSampleBufferBlcok(sampleBuffer);
        }
    }
}


#pragma mark - get
- (AVCaptureSession *)session
{
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        // 图片尺寸
        _session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    return _session;
}

//视频输出
- (AVCaptureVideoDataOutput *)videoOutput
{
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        // 15 : 每秒多少帧
        // minFrameDuration : 最小帧率
        _videoOutput.minFrameDuration = CMTimeMake(1, self.frameRaw);
        
        // videoSettings : 设置视频格式
        // YUV 和 RGB
        // 在苹果开发中,只要渲染,只支持RGB
        // YUV , 流媒体的时候,通常使用YUV
        // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange(YUV)
        // kCVPixelFormatType_32BGRA(RGB)
        _videoOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
        
        // alwaysDiscardsLateVideoFrames:延迟的时候,是否丢帧
        _videoOutput.alwaysDiscardsLateVideoFrames = YES;
        
        // 通过代理获取采集数据
        // queue:建议一定要使用同步队列,因为帧要有顺序
        // 创建同步队列
        dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", DISPATCH_QUEUE_SERIAL);
        [_videoOutput setSampleBufferDelegate:self queue:videoQueue];
    }
    return _videoOutput;
}

//视频写入
- (AVCaptureMovieFileOutput *)movieOutput
{
    if (!_movieOutput) {
        _movieOutput = [[AVCaptureMovieFileOutput alloc] init];
        //设置写入稳定性
        AVCaptureConnection *connect = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
        connect.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    return _movieOutput;
}

@end
