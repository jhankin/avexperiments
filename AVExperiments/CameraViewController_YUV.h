//
//  CameraViewController.h
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraViewController.h"

@interface CameraViewController_YUV : CameraViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    GLuint _lumaGluint;
    GLuint _chromaGluint;
}

@end
