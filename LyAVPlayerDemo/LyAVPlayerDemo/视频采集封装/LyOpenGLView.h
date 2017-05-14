//
//  LyOpenGLView.h
//  LyAVPlayerDemo
//
//  Created by 张杰 on 2017/5/14.
//  Copyright © 2017年 张杰. All rights reserved.
//  图片处理

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LyOpenGLView : UIView

- (void)displayWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

/*
 01-自定义图层类型
 02-初始化CAEAGLLayer图层属性
 03-创建EAGLContext
 04-创建渲染缓冲区
 05-创建帧缓冲区
 06-创建着色器
 07-创建着色器程序
 08-创建纹理对象
 09-YUA转RGB绘制纹理
 10-渲染缓冲区到屏幕
 11-清理内存
 */
