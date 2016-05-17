//
//  XZMachineCodeReader.m
//  XZMachineCodeReader
//
//  Created by MJH on 16/4/7.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "XZMachineCodeReader.h"

@import AVFoundation;

UIImage *XZMachineCodeImageFromNSData(NSData *aData, CGSize size) {
    // kCICategoryGenerator.CIQRCodeGenerator
    CIImage *qrcodeImage;
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [filter setValue:aData forKey:@"inputMessage"];
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    qrcodeImage = [filter outputImage];
    
    // Scale Transform
    CGSize imgSize = qrcodeImage.extent.size;
    CGFloat scaleX = size.width / imgSize.width;
    CGFloat scaleY = size.height / imgSize.height;
    CIImage *transformedImage = [qrcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    
    return [UIImage imageWithCIImage:transformedImage];
}

UIImage *XZMachineCodeImageFromNSString(NSString *aString, CGSize size) {
    NSData *aData = [aString dataUsingEncoding:NSUTF8StringEncoding];
    return XZMachineCodeImageFromNSData(aData, size);
}

#pragma mark - XZMachineCodeReader

@interface XZMachineCodeReader () <AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
    AVCaptureMetadataOutput *_captureMetadataOutput;
}

@end

@implementation XZMachineCodeReader

- (void)dealloc {
    [self stop];
}

- (void)setDelegate:(id<XZMachineCodeReaderDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
        if (_delegate != nil && _status == XZMachineCodeReaderStatusWaiting) {
            [self read];
        }
    }
}

- (BOOL)read {
    if (_status == XZMachineCodeReaderStatusStopped) {
        _status = XZMachineCodeReaderStatusWaiting;
        NSError *error = nil;
        // 用于扫描的设备
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        // 设备输入内容
        AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        if (captureDeviceInput == nil) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(machineCodeReader:didFailToScanWithError:)]) {
                [self.delegate machineCodeReader:self didFailToScanWithError:error];
            }
            return NO;
        }
        
        // 创建子线程
        dispatch_queue_t scanningQueue = [self _XZCreateScanningQueue];
        
        // 设备元数据输出
        _captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_captureMetadataOutput setMetadataObjectsDelegate:self queue:scanningQueue];    // 代理
        if (self.superview != nil) {
            [self setNeedsLayout];
        }
        // [captureMetadataOutput setRectOfInterest:CGRectMake(0.1, 0.1, 0.8, 0.8)];       // 处理扫描内容的范围
        
        // 输入输出会话
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession addInput:captureDeviceInput];
        
        // 输出图像到Layer
        _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:_videoPreviewLayer];
        [self setNeedsLayout];
        
        // 开始扫描
        [_captureSession startRunning];
        
        // 输出
        [_captureSession addOutput:_captureMetadataOutput];
        
        // 元数据类型，元数据输出添加到会话后，才能指定元数据类型，否则会报错
        [_captureMetadataOutput setMetadataObjectTypes:[self _XZMetadataObjectTypes]];
        
        _status = XZMachineCodeReaderStatusScanning;
    } else if (_status == XZMachineCodeReaderStatusWaiting) {
        [_captureSession addOutput:_captureMetadataOutput];
        if (_captureMetadataOutput.availableMetadataObjectTypes.count == 0) {
            [_captureMetadataOutput setMetadataObjectTypes:[self _XZMetadataObjectTypes]];
        }
        _status = XZMachineCodeReaderStatusScanning;
    }
    return YES;
}

- (void)stop {
    if (_status != XZMachineCodeReaderStatusStopped) {
        [_captureSession stopRunning];
        _captureSession = nil;
        [_videoPreviewLayer removeFromSuperlayer];
        _videoPreviewLayer = nil;
        _captureMetadataOutput = nil;
        _status = XZMachineCodeReaderStatusStopped;
    }
}

/**
 *  创建 AVCaptureMetadataOutput 代理方法执行的子线程
 *
 *  @return 子线程
 */
- (dispatch_queue_t)_XZCreateScanningQueue {
    dispatch_queue_t scanningQueue = dispatch_queue_create("kXZScanningQueue", NULL);
    return scanningQueue;
}

/**
 *  要扫描的类型。
 */
- (NSArray *)_XZMetadataObjectTypes {
    NSArray *metadataObjectTypes = [NSArray arrayWithObjects:AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode, nil];
    return metadataObjectTypes;
}

/**
 *
 */
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rectInWindow = [self.superview convertRect:self.frame toView:self.window];
    CGRect windowBounds = self.window.bounds;
    if (_videoPreviewLayer != nil) {
        // 视频输出视图
        CGRect frame = CGRectMake(-rectInWindow.origin.x, -rectInWindow.origin.y, windowBounds.size.width, windowBounds.size.height);
        _videoPreviewLayer.frame = frame;
        // NSLog(@"_videoPreviewLayer.frame: %@", NSStringFromCGRect(frame));
    }
    if (_captureMetadataOutput != nil) {
        CGRect selfBounds = self.bounds;
        // 修正扫描范围，MetadataOutput 的原点为右上角，横向 y 轴，纵向 x 轴。
        CGRect interest = CGRectMake(rectInWindow.origin.y / windowBounds.size.height, (windowBounds.size.width - CGRectGetMaxX(rectInWindow)) / windowBounds.size.width, selfBounds.size.height / windowBounds.size.height, selfBounds.size.width / windowBounds.size.width);
        // NSLog(@"interest: %@", NSStringFromCGRect(interest));
        [_captureMetadataOutput setRectOfInterest:interest];
    }
}

#pragma mark - 扫描结果处理对象处理完结果的代理方法

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        [_captureSession removeOutput:_captureMetadataOutput];
        _status = XZMachineCodeReaderStatusWaiting;
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(machineCodeReader:didReadObjects:)]) {
            NSMutableArray *result = nil;
            for (__kindof AVMetadataObject *object in metadataObjects) {
                if ([object.type isEqualToString:AVMetadataObjectTypeQRCode]) {
                    if (result == nil) {
                        result = [NSMutableArray array];
                    }
                    AVMetadataMachineReadableCodeObject *qrCodeObject = object;
                    NSString *stringValue = [qrCodeObject stringValue];
                    NSArray *corners = [qrCodeObject corners];
                    XZMachineReadableCodeObject *code = [XZMachineReadableCodeObject machineReadableCodeObject:stringValue corners:corners];
                    [result addObject:code];
                }
            }
            [self.delegate machineCodeReader:self didReadObjects:result];
        }
    }
}

@end


@implementation XZMachineReadableCodeObject

+ (instancetype)machineReadableCodeObject:(id)object corners:(NSArray *)corners {
    return [[self alloc] initWithObject:object corners:corners];
}

- (instancetype)initWithObject:(id)object corners:(NSArray *)corners {
    self = [super init];
    if (self != nil) {
        _object = object;
        _corners = corners;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>\nobject: %@\ncorners: %@\n", NSStringFromClass([self class]), self, self.object, self.corners];
}

@end
