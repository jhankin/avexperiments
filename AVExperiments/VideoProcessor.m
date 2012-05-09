//
//  VideoProcessor.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/7/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "VideoProcessor.h"

@implementation VideoProcessor

@synthesize dataOutput = _dataOutput;

- (id)init {
    self = [super init];
    if (self) {
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        dispatch_queue_t serialQueue = dispatch_queue_create("com.chronocide.avexperiments.videoprocessorqueue", DISPATCH_QUEUE_SERIAL);
        [output setSampleBufferDelegate:self queue:serialQueue];
        dispatch_release(serialQueue);
        self.dataOutput = output;
        [output release];
    }
    return self;
}

- (void)dealloc {
    [self.dataOutput setSampleBufferDelegate:nil queue:NULL];
    self.dataOutput = nil;
    [super dealloc];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate Method

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGSize presentationDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, YES, YES);
    NSLog(@"Buffer 0x%x: Duration: %f  Presentation dimensions: %@", (int)sampleBuffer, ((double)duration.value / (double)duration.timescale), NSStringFromCGSize(presentationDimensions));
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    NSLog(@"Buffer: %@", imageBuffer);
}

@end
