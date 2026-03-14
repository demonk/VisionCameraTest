//
//  ViewController.m
//  test
//
//  Created by ligs on 2026/3/11.
//

#import "ViewController.h"
#import "ChatViewController.h"
#import "VisionCameraViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width - 40, 40)];
    label.text = @"Welcome to test app";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];

    CGFloat buttonWidth = self.view.bounds.size.width - 80;
    CGFloat buttonHeight = 50;
    CGFloat buttonX = 40;
    CGFloat startY = 180;
    CGFloat spacing = 16;

    // Add open camera button
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cameraButton setTitle:@"打开摄像头" forState:UIControlStateNormal];
    cameraButton.frame = CGRectMake(buttonX, startY, buttonWidth, buttonHeight);
    cameraButton.backgroundColor = [UIColor systemBlueColor];
    [cameraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cameraButton.layer.cornerRadius = 12;
    [cameraButton addTarget:self action:@selector(openCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraButton];

    // Add show dialog button
    UIButton *dialogButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [dialogButton setTitle:@"显示对话框" forState:UIControlStateNormal];
    dialogButton.frame = CGRectMake(buttonX, CGRectGetMaxY(cameraButton.frame) + spacing, buttonWidth, buttonHeight);
    dialogButton.backgroundColor = [UIColor systemBlueColor];
    [dialogButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    dialogButton.layer.cornerRadius = 12;
    [dialogButton addTarget:self action:@selector(showDialog) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dialogButton];

    // Add chat button
    UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [chatButton setTitle:@"打开聊天界面" forState:UIControlStateNormal];
    chatButton.frame = CGRectMake(buttonX, CGRectGetMaxY(dialogButton.frame) + spacing, buttonWidth, buttonHeight);
    chatButton.backgroundColor = [UIColor systemBlueColor];
    [chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    chatButton.layer.cornerRadius = 12;
    [chatButton addTarget:self action:@selector(openChat) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:chatButton];

    // Add Vision Camera button
    UIButton *visionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [visionButton setTitle:@"Vision Camera" forState:UIControlStateNormal];
    visionButton.frame = CGRectMake(buttonX, CGRectGetMaxY(chatButton.frame) + spacing, buttonWidth, buttonHeight);
    visionButton.backgroundColor = [UIColor systemGreenColor];
    [visionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    visionButton.layer.cornerRadius = 12;
    [visionButton addTarget:self action:@selector(openVisionCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:visionButton];
}

- (void)openCamera {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"设备不支持摄像头"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)showDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"你好"
                                                                   message:@"这是一个测试对话框"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)openChat {
    ChatViewController *chatVC = [[ChatViewController alloc] init];
    chatVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:chatVC animated:YES completion:nil];
}

- (void)openVisionCamera {
    VisionCameraViewController *visionVC = [[VisionCameraViewController alloc] init];
    visionVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:visionVC animated:YES completion:nil];
}

@end

