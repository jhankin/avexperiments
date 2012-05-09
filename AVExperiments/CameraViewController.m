//
//  CameraViewController.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "CameraViewController.h"
#import "FZMacros.h"
#import "VideoProcessor.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@interface CameraViewController () {

}

@end

@implementation CameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _session = [[AVCaptureSession alloc] init];
        _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _serialQueue = dispatch_queue_create("com.chronocide.avexperiments.videoprocessorqueue", DISPATCH_QUEUE_SERIAL);
        [_dataOutput setSampleBufferDelegate:self queue:_serialQueue];
        
        NSArray *availableVideoCVPixelFormatTypes = _dataOutput.availableVideoCVPixelFormatTypes;
        if ([availableVideoCVPixelFormatTypes containsObject:[NSNumber numberWithInt:(int)'BGRA']]) {
            [_dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:(int)'BGRA']
                                                                      forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey]];
        }
    }
    return self;
}

- (void)dealloc {
    [_session release];
    [_dataOutput release];
    dispatch_release(_serialQueue);
    [_context release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
        _session.sessionPreset = AVCaptureSessionPresetMedium; 
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
  
    if ([_session canAddOutput:_dataOutput]) {
        [_session addOutput:_dataOutput];
    } else {
        NSLog(@"Session cannot add output %@.", _dataOutput);
    }
    [_session commitConfiguration];
    [_session startRunning];
    
    if (_context == nil)
    {
        _context = [[CIContext contextWithOptions:nil] retain];
    }
    
    if (_effectFilter == nil)
    {
        NSArray *filters = [CIFilter filterNamesInCategory:kCICategoryBuiltIn];
        NSLog(@"Available filters: %@", filters);
        _effectFilter = [[CIFilter filterWithName:@"CIFalseColor"] retain];
    }

//    self.view.layer.contentsGravity = kCAGravityResizeAspectFill;
//    self.view.layer.affineTransform = CGAffineTransformMakeRotation(DegreesToRadians(90.));

//    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//    [_imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
//    [self.view addSubview:_imageView];
//    [_imageView release];
        
    
    if (!_displayLayer) 
    {
        _displayLayer = [CALayer layer];
        [_displayLayer setFrame:self.view.layer.bounds];
        [self.view.layer addSublayer:_displayLayer];
    }
    
//    CALayer *viewLayer = self.view.layer;
//    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
//    captureVideoPreviewLayer.frame = self.view.bounds;
//    [viewLayer addSublayer:captureVideoPreviewLayer];
//    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [doneButton addTarget:self action:@selector(doneButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setFrame:CGRectMake(0, 0, doneButton.frame.size.width, doneButton.frame.size.height)];
    [self.view addSubview:doneButton];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [_context release];
    _context = nil;
    [_effectFilter release];
    _effectFilter = nil;
    [_session stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}

- (void)doneButtonPress:(id)sender {
    [_session stopRunning];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Notifications

- (void)captureSessionRuntimeError:(NSNotification *)notification {

}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate Method

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        // Image comes out in the wrong orientation, I don't know why.  Turn it to make it right.
        ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.0))];
        CGRect imageRect = [ciImage extent];
        
        [_effectFilter setValue:ciImage forKey:@"inputImage"];
        CGImageRef imageRef = [_context createCGImage:[_effectFilter valueForKey:@"outputImage"] fromRect:imageRect];
        dispatch_queue_t currentQueue = dispatch_get_current_queue();
        dispatch_retain(currentQueue);
        dispatch_async(dispatch_get_main_queue(), ^{
            _displayLayer.contents = (id)imageRef;
//            _imageView.image = [UIImage imageWithCGImage:imageRef];
            dispatch_async(currentQueue, ^{
                CGImageRelease(imageRef);
            });
            dispatch_release(currentQueue);
        });
    }
}

@end
