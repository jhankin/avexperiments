//
//  CameraViewController.h
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreVideo/CVOpenGLESTexture.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import "OpenGLView.h"

@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    CAEAGLLayer *_eaglLayer;
    
    AVCaptureSession *_session;
    AVCaptureVideoDataOutput *_dataOutput;
    dispatch_queue_t _serialQueue;

    AVCaptureVideoPreviewLayer *_previewLayer;
    CALayer *_displayLayer;
    UIImageView *_imageView;
    
    
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;    

}

@end
