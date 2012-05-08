//
//  CameraViewController.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "CameraViewController.h"
#import "FZMacros.h"

@interface CameraViewController () {
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureMovieFileOutput *_movieFileOutput;
}

@end

@implementation CameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _session = [[AVCaptureSession alloc] init];
        _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];

    }
    return self;
}

- (void)dealloc {
    [_session release];
    [_movieFileOutput release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        _session.sessionPreset = AVCaptureSessionPreset1280x720; 
    } else {
        _session.sessionPreset = AVCaptureSessionPresetHigh;
        
    }
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *device = nil;
    for (device in devices) {
        NSLog(@"Device name: %@", [device localizedName]);
        if ([device hasMediaType:AVMediaTypeVideo] && [device position] == AVCaptureDevicePositionBack) {
            break;
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        NSLog(@"No input created.  Error: %@", [error localizedDescription]);
    }
    
    [_session beginConfiguration];
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    } else {
        NSLog(@"Session cannot add input %@.", input);
    }
    
    CMTime maxDuration = CMTimeMakeWithSeconds(10, 1);
    _movieFileOutput.maxRecordedDuration = maxDuration;
    _movieFileOutput.minFreeDiskSpaceLimit = (1024 * 1000 * 1000) * 10;

    if ([_session canAddOutput:_movieFileOutput]) {
        [_session addOutput:_movieFileOutput];
    } else {
        NSLog(@"Session cannot add output %@.", _movieFileOutput);
    }
    [_session commitConfiguration];
    [_session startRunning];

        
    CALayer *viewLayer = self.view.layer;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    captureVideoPreviewLayer.frame = self.view.bounds;
    [viewLayer addSublayer:captureVideoPreviewLayer];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [doneButton addTarget:self action:@selector(doneButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setFrame:CGRectMake(0, 0, doneButton.frame.size.width, doneButton.frame.size.height)];
    [self.view addSubview:doneButton];
    
    
    NSString *timeIntervalString = [NSString stringWithFormat:@"%d", (int)[NSDate timeIntervalSinceReferenceDate]];
    NSString *tmpPath = [@"videos" stringByAppendingPathComponent:timeIntervalString];
    NSString *videoPath = FZ_DOCUMENT_PATH(tmpPath);
    videoPath = [videoPath stringByAppendingPathExtension:@"mov"];
    [_movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:videoPath] recordingDelegate:self];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [_session stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)doneButtonPress:(id)sender {
    [_session stopRunning];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Notifications

- (void)captureSessionRuntimeError:(NSNotification *)notification {

}

#pragma mark AVCaptureFileOutputRecordingDelegate Method

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput 
        didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL 
        fromConnections:(NSArray *)connections
        error:(NSError *)error {
    
    BOOL success = YES;
    if ([error code] != noErr) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            success = [value boolValue];
        }
    }
    
    if (!success) {
        NSLog(@"Error: %@", error);
    }
}

@end
