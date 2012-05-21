//
//  OpenGLView.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/21/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "OpenGLView.h"
#import <QuartzCore/QuartzCore.h>

@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

@end
