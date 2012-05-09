//
//  VideoProcessor.h
//  AVExperiments
//
//  Created by Joe Hankin on 5/7/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoProcessor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureVideoDataOutput *_dataOutput;
}

@property (nonatomic, retain) AVCaptureVideoDataOutput *dataOutput;

@end
