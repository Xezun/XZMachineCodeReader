//
//  XZMachineCodeReader.h
//  XZMachineCodeReader
//
//  Created by MJH on 16/4/7.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XZMachineCodeReaderDelegate;

@class XZMachineReadableCodeObject;

typedef NS_ENUM(NSInteger, XZMachineCodeReaderStatus) {
    XZMachineCodeReaderStatusStopped,
    XZMachineCodeReaderStatusScanning,
    XZMachineCodeReaderStatusWaiting
};

#pragma mark - 扫描二维码的

@interface XZMachineCodeReader : UIView

@property (nonatomic, weak) id<XZMachineCodeReaderDelegate> delegate;
@property (nonatomic, readonly) XZMachineCodeReaderStatus status;

- (BOOL)read;
- (void)stop;

@end

#pragma mark - 生成二维码的两个函数

UIImage *XZMachineCodeImageFromNSData(NSData *aData, CGSize size);
UIImage *XZMachineCodeImageFromNSString(NSString *aString, CGSize size);

@protocol XZMachineCodeReaderDelegate <NSObject>

@optional
- (void)machineCodeReader:(XZMachineCodeReader *)reader didFailToScanWithError:(NSError *)error;

/**
 *  当扫描到内容时，触发的代理方法。
 *  为了节省手机电量，此代理方法触发后，XZMachineCodeReader 会进入等待状。
 *  请在此方法中调用 -[XZMachineCodeReader read] 方法继续。
 *  该代理方法在子线程中被调用，刷新UI需要放到主线程中执行。
 */
- (void)machineCodeReader:(XZMachineCodeReader *)reader didReadObjects:(NSArray<XZMachineReadableCodeObject *> *)objects;

@end


@interface XZMachineReadableCodeObject : NSObject

@property (nonatomic, strong) id object;  // 目前而言，这个一般是 NSString 或者 nil。
@property (nonatomic, strong) NSArray *corners;

+ (instancetype)machineReadableCodeObject:(id)object corners:(NSArray *)corners;
- (instancetype)initWithObject:(id)object corners:(NSArray *)corners;

@end