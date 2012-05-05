//
//  RootViewController.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "RootViewController.h"
#import "CameraViewController.h"
#import "ShowVideosViewController.h"
#import "FZMacros.h"
@interface RootViewController ()

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSString *path = [FZ_DOCUMENT_PATH(@"videos") retain];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory;
        NSError *error = nil;
        if (!([fileManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory)) {
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (error) {
            NSLog(@"Error: %@", error);
        }
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    _startSessionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_startSessionButton setBounds:CGRectMake(0, 0, 160, 60)];
    [_startSessionButton setCenter:CGPointMake(self.view.center.x, self.view.center.y - 70)];
    [_startSessionButton setTitle:@"Start Session" forState:UIControlStateNormal];
    [_startSessionButton addTarget:self action:@selector(startSessionButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startSessionButton];
    
    _showVideosButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_showVideosButton setBounds:CGRectMake(0, 0, 160, 60)];
    [_showVideosButton setCenter:CGPointMake(self.view.center.x, self.view.center.y + 70)];
    [_showVideosButton setTitle:@"Show Videos" forState:UIControlStateNormal];
    [_showVideosButton addTarget:self action:@selector(showVideosButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_showVideosButton];
    
	// Do any additional setup after loading the view.
}

- (void)startSessionButtonPress:(id)sender {
    CameraViewController *cameraViewController = [[CameraViewController alloc] init];
    [self presentModalViewController:cameraViewController animated:YES];
    [cameraViewController release];
}

- (void)showVideosButtonPress:(id)sender {
    
    ShowVideosViewController *showVideosController = [[ShowVideosViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:showVideosController];
    [showVideosController release];
    [self presentModalViewController:navController animated:YES];
    [navController release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
