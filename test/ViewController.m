//
//  ViewController.m
//  test
//
//  Created by ligs on 2026/3/11.
//

#import "ViewController.h"
#import "ChatViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // 添加打开摄像头按钮
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cameraButton setTitle:@"打开摄像头" forState:UIControlStateNormal];
    cameraButton.frame = CGRectMake(100, 200, 200, 50);
    cameraButton.center = self.view.center;
    [cameraButton addTarget:self action:@selector(openCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraButton];

    // 添加显示对话框按钮
    UIButton *dialogButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [dialogButton setTitle:@"显示对话框" forState:UIControlStateNormal];
    dialogButton.frame = CGRectMake(cameraButton.frame.origin.x, cameraButton.frame.origin.y + cameraButton.frame.size.height + 50, cameraButton.frame.size.width, cameraButton.frame.size.height);
    [dialogButton addTarget:self action:@selector(showDialog) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dialogButton];

    // 添加打开聊天界面按钮
    UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [chatButton setTitle:@"打开聊天界面" forState:UIControlStateNormal];
    chatButton.frame = CGRectMake(dialogButton.frame.origin.x, dialogButton.frame.origin.y + dialogButton.frame.size.height + 50, dialogButton.frame.size.width, dialogButton.frame.size.height);
    [chatButton addTarget:self action:@selector(openChat) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:chatButton];
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

@end
