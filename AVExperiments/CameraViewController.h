//
//  CameraViewController.h
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession *_session;
    AVCaptureVideoDataOutput *_dataOutput;
    dispatch_queue_t _serialQueue;

    AVCaptureVideoPreviewLayer *_previewLayer;
    CIContext *_context;
    CIFilter *_effectFilter;
    CALayer *_displayLayer;
    UIImageView *_imageView;
}

@end
