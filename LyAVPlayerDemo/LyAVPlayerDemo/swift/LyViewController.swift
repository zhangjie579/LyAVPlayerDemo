//
//  LyViewController.swift
//  001
//
//  Created by 张杰 on 2017/3/30.
//  Copyright © 2017年 张杰. All rights reserved.
//

import UIKit
import AVFoundation

fileprivate let kScreenW = UIScreen.main.bounds.size.width
fileprivate let kScreenH = UIScreen.main.bounds.size.height

class LyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    fileprivate lazy var videoQueue = DispatchQueue.global()
    fileprivate lazy var audioQueue = DispatchQueue.global()
    
    //创建捕捉会话
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    //预览图层
    fileprivate lazy var preViewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    fileprivate var videoInput : AVCaptureDeviceInput?
    fileprivate var movieOutput : AVCaptureMovieFileOutput?//写入
}

extension LyViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        if connection == videoOutput?.connection(withMediaType: AVMediaTypeVideo) {
            print("已经采集视频画面")
        }
        else {
            print("已经采集音频")
        }
        
    }
}

//MARK: 切换摄像头
extension LyViewController {
    
    func changeScene() {
        //1.获得之前的镜头
        guard var position = videoInput?.device.position else { return }
        
        //2.获得当前应该显示的镜头
        position = position == .front ? .back : .front
        
        //3.根据当前镜头创建新的device
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice]
        guard let device = devices?.filter({ $0.position == position }).first else { return }
        
        //4.根据新的device创建新的input
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        //5.在session中切换
        session.beginConfiguration()
        session.removeInput(self.videoInput!)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        session.commitConfiguration()
        self.videoInput = videoInput
        
    }
}

//视频采集/停止采集
extension LyViewController {
    
    //开始采集视频
    func startCapture() {
        
        //1.设置视频的输入，输出
        setupVideo()
        
        //2.设置音频的输入，输出
        setupAudio()
        
        //3.添加写入文件的output
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
        self.movieOutput = movieOutput
        
        //设置写入的稳定性
        let connection = movieOutput.connection(withMediaType: AVMediaTypeVideo)
        connection?.preferredVideoStabilizationMode = .auto
        
        //4.给用户看到一个预览图层(可选)
        preViewLayer.frame = view.bounds
        view.layer.addSublayer(preViewLayer)
        
        //5.开始采集
        session.startRunning()
        
        //6.开始讲采集到的画面，写入到文件中
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        let url = URL(fileURLWithPath: path)
        movieOutput.startRecording(toOutputFileURL: url, recordingDelegate: self)
    }
    
    func setupVideo() {
        //1.创建捕捉会话
        
        //2.给捕捉会话设置输入源（摄像头）
        //2.1获取摄像头
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else {
            print("摄像头不可用")
            return
        }
        //        let device = devices.filter { (device : AVCaptureDevice) -> Bool in
        //            return device.position == .front
        //        }.first
        
        guard let device = devices.filter({ $0.position == .front}).first else { return }
        
        //2.2通过device创建 对象
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        self.videoInput = videoInput
        
        //2.3将input添加到会话中
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        //3.给捕捉会话设置输出源
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        self.videoOutput = videoOutput
        
//        //4.获取video对于的connection
//        connection = videoOutput.connection(withMediaType: AVMediaTypeVideo)
    }
    
    func setupAudio() {
        //1.设置音频的输入（话筒）
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) else { return }
        
        //1.2根据device创建AVCaptureDeviceInput
        guard let audioInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        //1.3将input添加到会话中
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        //2.给会话设置音频输出源
        let audioOutput = AVCaptureVideoDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        }
        
    }
    
    //停止采集视频
    func stopCapture() {
        
        //停止写入
        movieOutput?.stopRecording()
        
        session.stopRunning()
        preViewLayer.removeFromSuperlayer()
    }
}

//MARK:直播点赞
//https://my.oschina.net/shengbingli/blog/804456
extension LyViewController {
    
    func animationForHeart() {
        let imageV = UIImageView()
        imageV.frame = CGRect(x: kScreenW - CGFloat(84), y: kScreenH - CGFloat(58), width: 25, height: 25)
        imageV.backgroundColor = UIColor.clear
        imageV.clipsToBounds = true
        self.view.addSubview(imageV)
        
        // UInt32(0.9)
        let starX : CGFloat = CGFloat(round(Double(arc4random() % 300)))
        var scale  = round(Double(arc4random() % 2 + 1))
        let speed  = 1 / round(Double(arc4random() % 900) ) + 0.4
        let imageName = Int(round(Double(arc4random() % 10)))
        let name = String(format: "XJDomain.bundle/heart%d.png", imageName)
        imageV.image = UIImage(named: name)
        let x = (kScreenW - starX) * 1.5
        if scale >= 1.2 {
            scale = 1.2
        }
        
        UIView.animate(withDuration: 7 * speed, animations: {
            imageV.frame = CGRect(x: x, y: kScreenH - 400, width: CGFloat(25 * scale), height: CGFloat(25 * scale))
        }, completion: { (_) in
            imageV.removeFromSuperview()
        })
    }
}

extension LyViewController : AVCaptureFileOutputRecordingDelegate {
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("开始写入文件")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("结束写入文件")
    }
}





