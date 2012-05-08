//
//  ShowVideosViewController.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "ShowVideosViewController.h"
#import "PlayerViewController.h"
#import "FZMacros.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ShowVideosViewController () {
    NSArray *_filenames;
    NSString *_path;
    
    UITableView *_tableView;
}

- (void)loadFilenames;

@end

@implementation ShowVideosViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self loadFilenames];
    }
    return self;
}

- (void)dealloc {
    [_filenames release];
    [_path release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    [_tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    
    [self.view addSubview:_tableView];
    [_tableView release];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPress:)] autorelease];
}

- (void)loadFilenames {
    FZ_SAFE_RELEASE(_path);
    FZ_SAFE_RELEASE(_filenames);
    _path = [FZ_DOCUMENT_PATH(@"videos") retain];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    _filenames = [[fileManager contentsOfDirectoryAtPath:_path error:&error] retain];
    if (error) {
        NSLog(@"Error listing directory at path %@: %@", _path, error);
    }
}
     
- (void)doneButtonPress:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_filenames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"videoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier] autorelease];
    }
    
    [cell.textLabel setText:[_filenames objectAtIndex:indexPath.row]];
    [cell.detailTextLabel setText:@"OK, this might be a video."];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *filePath = [_path stringByAppendingPathComponent:[_filenames objectAtIndex:indexPath.row]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    PlayerViewController *playerViewController = [[PlayerViewController alloc] initWithFileURL:fileURL];
    [self.navigationController pushViewController:playerViewController animated:YES];
    [playerViewController release];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *filePath = [_path stringByAppendingPathComponent:[_filenames objectAtIndex:indexPath.row]];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!error) {
            [self loadFilenames];
            [_tableView reloadData];
        } else {
            NSString *errorMessage = [error localizedDescription];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    }
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
