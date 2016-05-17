//
//  ViewController.m
//  JWZSQCodeScanner
//
//  Created by MJH on 16/4/7.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "ViewController.h"

#import "XZMachineCodeReader.h"

@interface ViewController () <XZMachineCodeReaderDelegate>

@property (weak, nonatomic) IBOutlet UIView *view1;

@property (nonatomic, strong) XZMachineCodeReader *scanner;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _scanner = [[XZMachineCodeReader alloc] initWithFrame:self.view1.frame];
    _scanner.delegate = self;
    [self.view insertSubview:_scanner atIndex:0];
    
    self.imageView.image = XZMachineCodeImageFromNSString(@"这是一个二维码！", CGSizeMake(150, 150));
}

- (IBAction)buttonAction:(UIButton *)sender {
    if (_scanner.status != XZMachineCodeReaderStatusScanning) {
        [sender setTitle:@"Stop" forState:(UIControlStateNormal)];
        [_scanner read];
    } else {
        [sender setTitle:@"Scan" forState:(UIControlStateNormal)];
        [_scanner stop];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)machineCodeReader:(XZMachineCodeReader *)reader didFailToScanWithError:(NSError *)error {
    NSLog(@"%@", [error localizedDescription]);
}

- (void)machineCodeReader:(XZMachineCodeReader *)reader didReadObjects:(NSArray<XZMachineReadableCodeObject *> *)objects {
    NSLog(@"%@", objects.lastObject.object);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [reader read];
    });
}

@end
