//
//  SPECameraViewController.mm
//  Insta3D_iOS-Sample
//
//  Created by Daniel on 2015/11/25.
//  Copyright © 2015年 Speed 3D Inc. All rights reserved.
//

#import "SPECameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+SPEOrientation.h"

@interface SPECameraViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, strong) NSString *unityObjectName;
@property(nonatomic, strong) NSString *unityFunctionName;

@property(nonatomic, strong) UIView *videoView;
@property(nonatomic, strong) UIView *bottomView;

@property(nonatomic, strong) AVCaptureSession *frontCameraSession;
@property(nonatomic, strong) AVCaptureStillImageOutput *frontCameraStillImageOutput;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *frontCameraPreviewLayer;

@property(nonatomic, strong) AVCaptureSession *backCameraSession;
@property(nonatomic, strong) AVCaptureStillImageOutput *backCameraStillImageOutput;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *backCameraPreviewLayer;

@property(nonatomic) BOOL ifNeedShowCameraDeniedMessage;

@end

@implementation SPECameraViewController

- (void)loadView {
    [super loadView];
    
    self.view = [[UIView alloc] init];
    [self setupHelpButton];
    [self setupCloseButton];
    [self setupBottomView];
    [self setupVideoView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ifNeedShowCameraDeniedMessage = NO;
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            [self setupCamera];
            break;
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self setupCamera];
                }
                else {
                    self.ifNeedShowCameraDeniedMessage = YES;
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
            self.ifNeedShowCameraDeniedMessage = YES;
            break;
        case AVAuthorizationStatusDenied:
            self.ifNeedShowCameraDeniedMessage = YES;
            break;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.frontCameraPreviewLayer.frame = self.videoView.bounds;
    self.backCameraPreviewLayer.frame = self.videoView.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.frontCameraSession startRunning];
    [self.backCameraSession stopRunning];
    self.frontCameraPreviewLayer.hidden = NO;
    self.backCameraPreviewLayer.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.ifNeedShowCameraDeniedMessage) {
        [self cameraDenied];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)saveImage:(UIImage *)image {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"SPE"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    path = [path stringByAppendingPathComponent:@"tmpImage.jpg"];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    
    return [imageData writeToFile:path atomically:YES] ? path : nil;
}

- (void)sendImagePathToUnity:(NSString *)path {
    UnitySendMessage(self.unityObjectName.UTF8String, self.unityFunctionName.UTF8String, (path ?  : @"").UTF8String);
}

#pragma mark - layout

- (void)setupHelpButton {
    UIImage *image = [UIImage imageNamed:@"Create_camera_ico_info_n"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.showsTouchWhenHighlighted = NO;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"Create_camera_ico_info_p"] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(helpAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:20]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
}

- (void)setupCloseButton {
    UIImage *image = [UIImage imageNamed:@"Create_camera_ico_close_n"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.showsTouchWhenHighlighted = NO;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"Create_camera_ico_close_p"] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:20]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
}

- (void)setupBottomView {
    [self.view addSubview:self.bottomView];
    
    [self.bottomView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    
    [self setupBottomBackground];
}

- (void)setupBottomBackground {
    UIImage *image;
    UIButton *button;
    
    image = [UIImage imageNamed:@"create_camera_plane_L"];
    UIImageView *planeLImageView = [[UIImageView alloc] initWithImage:image];
    planeLImageView.backgroundColor = [UIColor clearColor];
    [self.bottomView addSubview:planeLImageView];
    
    [planeLImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:planeLImageView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeLImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeLImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [planeLImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeLImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [planeLImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeLImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];

    image = [UIImage imageNamed:@"icon_create_camera_photos"];
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.showsTouchWhenHighlighted = NO;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"icon_create_camera_photos_pressed"] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(albumAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:button];
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:planeLImageView attribute:NSLayoutAttributeBottom multiplier:1 constant:-13]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:planeLImageView attribute:NSLayoutAttributeLeft multiplier:1 constant:12]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
    
    
    image = [UIImage imageNamed:@"create_camera_plane_bg"];
    UIImageView *planeBGImageView = [[UIImageView alloc] initWithImage:image];
    planeBGImageView.contentMode = UIViewContentModeScaleToFill;
    planeBGImageView.backgroundColor = [UIColor clearColor];
    [self.bottomView addSubview:planeBGImageView];
    
    [planeBGImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:planeBGImageView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeBGImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeBGImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:planeLImageView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [planeBGImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeBGImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
    
    
    image = [UIImage imageNamed:@"create_camera_plane_M"];
    UIImageView *planeMImageView = [[UIImageView alloc] initWithImage:image];
    planeMImageView.backgroundColor = [UIColor clearColor];
    [self.bottomView addSubview:planeMImageView];
    
    [planeMImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:planeMImageView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeMImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeMImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:planeBGImageView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeMImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [planeMImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeMImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [planeMImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeMImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
    
    image = [UIImage imageNamed:@"create_camera_btn_camera"];
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.showsTouchWhenHighlighted = NO;
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(shutterAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:button];
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:planeMImageView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:planeMImageView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
    
    
    image = [UIImage imageNamed:@"create_camera_plane_bg"];
    planeBGImageView = [[UIImageView alloc] initWithImage:image];
    planeBGImageView.contentMode = UIViewContentModeScaleToFill;
    planeBGImageView.backgroundColor = [UIColor clearColor];
    [self.bottomView addSubview:planeBGImageView];
    
    [planeBGImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:planeBGImageView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeBGImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeBGImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:planeMImageView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [planeBGImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeBGImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
    
    
    image = [UIImage imageNamed:@"create_camera_plane_R"];
    UIImageView *planeRImageView = [[UIImageView alloc] initWithImage:image];
    planeRImageView.backgroundColor = [UIColor clearColor];
    [self.bottomView addSubview:planeRImageView];
    
    [planeRImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:planeRImageView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeRImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeRImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:planeBGImageView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:planeRImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [planeRImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeRImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [planeRImageView addConstraint:[NSLayoutConstraint constraintWithItem:planeRImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
    
    image = [UIImage imageNamed:@"icon_create_camera_switch"];
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.showsTouchWhenHighlighted = NO;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"icon_create_camera_switch_pressed"] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(switchCameraAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:button];
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:planeRImageView attribute:NSLayoutAttributeBottom multiplier:1 constant:-13]];
    [self.bottomView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:planeRImageView attribute:NSLayoutAttributeRight multiplier:1 constant:-12]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.width]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:image.size.height]];
}

- (void)setupVideoView {
    [self.view insertSubview:self.videoView atIndex:0];
    
    [self.videoView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.videoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:15]];
}

#pragma mark - action

- (void)helpAction:(UIButton *)sender {
    
}

- (void)closeAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}

- (void)albumAction:(UIButton *)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)shutterAction:(UIButton *)sender {
    AVCaptureStillImageOutput *stillImageOutput;
    
    if (self.backCameraPreviewLayer.hidden) {
        stillImageOutput = self.frontCameraStillImageOutput;
    }
    else {
        stillImageOutput = self.backCameraStillImageOutput;
    }
    
    AVCaptureConnection *connection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // update the video orientation to the device one
    if (connection.supportsVideoOrientation) {
        AVCaptureVideoOrientation orientation;
        switch ([[UIDevice currentDevice] orientation]) {
            case UIDeviceOrientationPortrait:
                orientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                orientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            case UIDeviceOrientationLandscapeLeft:
                orientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                orientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            default:
                orientation = AVCaptureVideoOrientationPortrait;
                break;
        }
        connection.videoOrientation = orientation;
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!error) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                image = [image fixOrientation];
                __block NSString *imagePath = [self saveImage:image];
                
                [self dismissViewControllerAnimated:YES completion:^{
                    [self sendImagePathToUnity:imagePath];
                }];
            }
        }
        else {
            NSLog(@"[SPE] error while capturing still image: %@", error);
        }
    }];
}

- (void)switchCameraAction:(UIButton *)sender {
    if (self.frontCameraPreviewLayer.hidden) {
        [self.backCameraSession stopRunning];
        [self.frontCameraSession startRunning];
    }
    else {
        [self.frontCameraSession stopRunning];
        [self.backCameraSession startRunning];
    }
    
    self.backCameraPreviewLayer.hidden = !self.backCameraPreviewLayer.hidden;
    self.frontCameraPreviewLayer.hidden = !self.backCameraPreviewLayer.hidden;
}

#pragma mark - camera

- (void)setupCamera {
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            NSError *error = nil;
            AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            if (error) {
                NSLog(@"[SPE] device input error: %@", error);
                continue;
            }
            switch (device.position) {
                case AVCaptureDevicePositionFront:
                    [self.frontCameraSession addInput:cameraInput];
                    
                    if ([self.frontCameraSession canAddOutput:self.frontCameraStillImageOutput]) {
                        [self.frontCameraSession addOutput:self.frontCameraStillImageOutput];
                    }
                    
                    self.frontCameraPreviewLayer.session = self.frontCameraSession;
                    self.frontCameraPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                    
                    [self.videoView.layer addSublayer:self.frontCameraPreviewLayer];
                    break;
                case AVCaptureDevicePositionBack:
                    [self.backCameraSession addInput:cameraInput];
                    
                    if ([self.backCameraSession canAddOutput:self.backCameraStillImageOutput]) {
                        [self.backCameraSession addOutput:self.backCameraStillImageOutput];
                    }
                    
                    self.backCameraPreviewLayer.session = self.backCameraSession;
                    self.backCameraPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                    
                    [self.videoView.layer addSublayer:self.backCameraPreviewLayer];
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)cameraDenied {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *alertText;
    NSURL *openSettingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (openSettingsURL) {
        alertText = NSLocalizedString(@"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Touch Privacy.\n\n3. Turn the Camera on.\n\n4. Open this app and try again.", nil);
        
        [alertView addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Go", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:openSettingsURL];
        }]];
    }
    else {
        alertText = NSLocalizedString(@"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Close this app.\n\n2. Open the Settings app.\n\n3. Scroll to the bottom and select this app in the list.\n\n4. Touch Privacy.\n\n5. Turn the Camera on.\n\n6. Open this app and try again.", nil);
    }
    alertView.message = alertText;
    
    [alertView addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self presentViewController:alertView animated:YES completion:nil];
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    __block NSString *imagePath = nil;
    
    if (image) {
        image = [image fixOrientation];
        imagePath = [self saveImage:image];
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [self dismissViewControllerAnimated:YES completion:^{
            [self sendImagePathToUnity:imagePath];
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - lazily initialized

- (UIView *)videoView {
    if (!_videoView) {
        _videoView = [[UIView alloc] init];
        _videoView.backgroundColor = [UIColor clearColor];
    }
    return _videoView;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor clearColor];
    }
    return _bottomView;
}

- (AVCaptureSession *)frontCameraSession {
    if (!_frontCameraSession) {
        _frontCameraSession = [[AVCaptureSession alloc] init];
        _frontCameraSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _frontCameraSession;
}

- (AVCaptureSession *)backCameraSession {
    if (!_backCameraSession) {
        _backCameraSession = [[AVCaptureSession alloc] init];
        _backCameraSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _backCameraSession;
}

- (AVCaptureStillImageOutput *)frontCameraStillImageOutput {
    if (!_frontCameraStillImageOutput) {
        _frontCameraStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    return _frontCameraStillImageOutput;
}

- (AVCaptureStillImageOutput *)backCameraStillImageOutput {
    if (!_backCameraStillImageOutput) {
        _backCameraStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    return _backCameraStillImageOutput;
}

- (AVCaptureVideoPreviewLayer *)frontCameraPreviewLayer {
    if (!_frontCameraPreviewLayer) {
        _frontCameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] init];
    }
    return _frontCameraPreviewLayer;
}

- (AVCaptureVideoPreviewLayer *)backCameraPreviewLayer {
    if (!_backCameraPreviewLayer) {
        _backCameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] init];
    }
    return _backCameraPreviewLayer;
}

@end

static SPECameraViewController *cameraViewController = nil;

extern "C" {
    /**
     呼叫 _ShowCameraView 可把客製化layout的iOS原生相機喚醒
     同時要指定callback目標的gameObject名稱及function name
     callback只有一個參數，呼叫時間為使用者拍攝或選取完照片，取消拍攝則不會呼叫
     參數內容為拍照後圖檔的存放路徑，如果內容為空字串時，代表存檔失敗
     */
    void _ShowCameraView(const char* objectName, const char* functionName) {
        if (!cameraViewController) {
            cameraViewController = [[SPECameraViewController alloc] init];
        }
        
        cameraViewController.unityObjectName = [NSString stringWithUTF8String:objectName];
        cameraViewController.unityFunctionName = [NSString stringWithUTF8String:functionName];
        
        UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [rootViewController presentViewController:cameraViewController animated:YES completion:nil];
    }
}
