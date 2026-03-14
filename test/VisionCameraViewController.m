//
//  VisionCameraViewController.m
//  test
//
//  Created by ligs on 2026/3/15.
//

#import "VisionCameraViewController.h"
#import "test-Swift.h"

@interface VisionCameraViewController ()

@end

@implementation VisionCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Present the SwiftUI ContentView using ContentViewWrapper
    __weak typeof(self) weakSelf = self;
    UIViewController *hostingVC = [ContentViewWrapper createHostingControllerOnDismiss:^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];

    [self addChildViewController:hostingVC];
    hostingVC.view.frame = self.view.bounds;
    hostingVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:hostingVC.view];
    [hostingVC didMoveToParentViewController:self];
}

@end
