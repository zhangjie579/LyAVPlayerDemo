//
//  ViewController.m
//  LyAVPlayerDemo
//
//  Created by 张杰 on 2017/5/13.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

// 经验:只要发现苹果原生的类属性和方法比较少,一般都是基类,需要再次去寻找子类,根据功能
// AVCaptureDevice(摄像头,麦克风),本质并不能够输出东西

// AVCaptureInput 管理采集的数据

// AVCaptureOutput 管理设备数据输出(视频文件,一张图片)

//  AVCaptureSession: 管理输入到输出数据

// AVCaptureSession给它指定一个输入和输出设备,就会在输入和输出设备中建立连接AVCaptureConnection

//  AVCaptureVideoPreviewLayer: 展示采集数据

//  AVCaptureVideoDataOutput: 获取视频设备输出数据
//  AVCaptureAudioDataOutput: 获取音频设备输出数据

/*
 采集视频 -> 摄像头
 
 采集音频 -> 麦克风
 */

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureSession          *session;//会话
@property (nonatomic, strong) AVCaptureVideoDataOutput  *videoOutput;//视频输出
@property (nonatomic, strong) AVCaptureDeviceInput      *videoInput;//视频输入
@property (nonatomic, strong) AVCaptureMovieFileOutput  *movieOutput;//写入沙盒
@property (nonatomic, strong) UIImageView               *imageView;

@end

/*
 1.创建会话
 2.创建输入 -> 输入需要设置 -> 创建设备,同时视频设备需要设置是前置还是后置摄像头
 3.创建输出
 4.添加输入/输出
 5.连接
 */

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.捕获视频数据
    [self captureVideo];
    
    //2.捕获音频数据
    [self captureAudio];
    
    //3.开始捕获数据
    [self.session startRunning];
    
    //4.写入
//    [self writeToCache];
    
    [self.view addSubview:self.imageView];
}

#pragma mark - 视频写入

//视频写入
- (void)writeToCache
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/demo.mp4"];
    
    if ([self.session canAddOutput:self.movieOutput]) {
        [self.session addOutput:self.movieOutput];
    }
    
    [self.movieOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:path] recordingDelegate:self];
}

//---------------------  AVCaptureFileOutputRecordingDelegate  ---------------

//开始写入
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    
}

//写入完成
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    
}

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
- (void)captureVideo
{
    //1.获取前置摄像头照相机
    AVCaptureDevice *videoDevice = [self videoDeviceWithPostion:AVCaptureDevicePositionFront];
    videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15);
    
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
    videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    videoConnection.automaticallyAdjustsVideoMirroring = NO;
    videoConnection.videoMirrored = YES;
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

#pragma mark - delegate

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
// 只要获取一帧数据就会调用
// CVPixelBufferRef = CVImageBufferRef
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
#warning 注意:这个是在异步的串行队列
    if (self.videoOutput == captureOutput) {
        [self dealVideoData:sampleBuffer];
    } else {
        NSLog(@"获取音频数据");
    }
    // 判断是音频还是视频
    
    
}

// 处理图片
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // 获取原图片信息
    CVImageBufferRef imageRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *img = [CIImage imageWithCVImageBuffer:imageRef];
    
    // 获取有哪些滤镜可以处理图片
    NSArray *filters = [img autoAdjustmentFilters];
    //
    //    for (CIFilter *filter in filters) {
    //        NSLog(@"%@",filter.name);
    //    }
    //
    //    NSLog(@"%@",[filters.firstObject class]);
    
    // CIFiter:滤镜
    // 一个滤镜属于多个分类
    // 获取滤镜名称
    //    NSArray *filterNames = [CIFilter filterNamesInCategory:kCICategoryVideo];
    
    // 创建滤镜
    // CIFilter通过KVC
    // attributes:获取CIFilter属性对应类型
    // inputKeys:获取CIFilter哪些属性可以设置
    // CIExposureAdjust:亮度
    CIFilter *fiter = [CIFilter filterWithName:@"CIFaceBalance"];
    /*
     inputImage,
     inputOrigI,
     inputOrigQ,
     inputStrength,
     inputWarmth
     */
    //    [fiter setValue:@0 forKey:@"inputEV"];
    [fiter setValue:img forKey:@"inputImage"];
    [fiter setValue:@2 forKey:@"inputStrength"];
    [fiter setValue:@1 forKey:@"inputWarmth"];
    
    img = fiter.outputImage;
    
    UIImage *image = [UIImage imageWithCIImage:img];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });
    // inputEV
    
    //    NSLog(@"%@",fiter.attributes);
    
    // 通过滤镜名称创建对应的CIFiter
    //    CIFilter
    
}

- (void)dealVideoData:(CMSampleBufferRef)sampleBuffer
{
    // sampleBuffer:一帧数据
    // sampleBuffer -> CIImage -> UIImage
    // CoreImage:处理底层图片信息
    CVImageBufferRef imageRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *img = [CIImage imageWithCVImageBuffer:imageRef];
    
    UIImage *image = [UIImage imageWithCIImage:img];
    
    // 回到主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.imageView.image = image;
        
    });
}



// 丢帧就会调用
- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
}

// 获取一帧播放时长
// CMSampleBufferGetDuration(<#CMSampleBufferRef  _Nonnull sbuf#>) 计算视频时长
// CMBlockBufferRef:把图片压缩之后的数据
// CMSampleBufferCreate:压缩之后,解码显示
// 获取图片信息
//   CMSampleBufferGetImageBuffer(<#CMSampleBufferRef  _Nonnull sbuf#>)
// 获取帧尺寸
//    CMSampleBufferGetSampleSize(<#CMSampleBufferRef  _Nonnull sbuf#>, <#CMItemIndex sampleIndex#>)
// 编码
// VideoToolbox:硬编码 帧数据经过H.264压缩 NAL(PTS,DTS,I,P,B)
//    // PTS:展示时间
//    CMSampleBufferGetPresentationTimeStamp(<#CMSampleBufferRef  _Nonnull sbuf#>)
//
//    // DTS:帧压缩时间
//    CMSampleBufferGetDecodeTimeStamp(<#CMSampleBufferRef  _Nonnull sbuf#>)

// 获取帧格式,通过它获取PTS,DTS
//    CMSampleBufferGetFormatDescription(<#CMSampleBufferRef  _Nonnull sbuf#>)

#pragma mark - 停止

- (void)stopCapture
{
    //停止写入
    [self.movieOutput stopRecording];
    
    [self.session stopRunning];
}

#pragma mark - get
- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        
//        _imageView.layer.anchorPoint = CGPointMake(0, 0);
//        
//        _imageView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
//        _imageView.transform = CGAffineTransformMakeTranslation([UIScreen mainScreen].bounds.size.width, 0);
//        
//        _imageView.transform = CGAffineTransformRotate(_imageView.transform, M_PI_2);
        
        _imageView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    return _imageView;
}

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
        _videoOutput.minFrameDuration = CMTimeMake(1, 15);
        
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
