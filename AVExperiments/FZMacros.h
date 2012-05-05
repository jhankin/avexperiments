//
//  FZMacros.h
//  FZFramework
//
//  Created by Joseph Hankin on 9/15/11.
//  Copyright 2011 Fuzz Productions. All rights reserved.
//


////////////////////////////////////////////////
// Standard Paths
////////////////////////////////////////////////
#define FZ_DOCUMENT_PATH(inPath) [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:inPath]
#define FZ_BUNDLE_PATH(inPath) [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:inPath]
#define FZ_TEMPORARY_PATH(inPath) [NSTemporaryDirectory() stringByAppendingPathComponent:inPath]

////////////////////////////////////////////////
// Memory Management
////////////////////////////////////////////////
#define FZ_SAFE_RELEASE(instance)		\
			if (instance != nil) {		\
				[instance release];		\
				instance = nil;			\
			}

////////////////////////////////////////////////
// Strings
////////////////////////////////////////////////
#define FZ_IS_EMPTY_STRING(inString) (!inString || (NSNull *)inString == [NSNull null] || [[inString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] || [[inString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"<null>"])

#define FZ_STRING_OR_NIL(inString) ( IsEmptyString(inString) ? nil : inString )
#define FZ_STRING_FROM_INT(x) [NSString stringWithFormat:@"%d", x]
#define FZ_PERCENTAGE_FROM_FLOAT(x) [NSString stringWithFormat:@"%d%%", (int)((float)x * 100.0)]

////////////////////////////////////////////////
// Design Constants
////////////////////////////////////////////////
#define FZ_AUTORESIZE_TO_FIT UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin

////////////////////////////////////////////////
// Colors
////////////////////////////////////////////////
#define FZ_RGB_COLOR(r, g, b) [UIColor colorWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:1.0f]
#define FZ_RGB_ALPHA_COLOR(r, g, b, a) [UIColor colorWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:(a < 1.0 ? a : (a / 255.0f))]

////////////////////////////////////////////////
// Interface
////////////////////////////////////////////////
#define FZ_IS_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define FZ_IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

////////////////////////////////////////////////
// Logging
////////////////////////////////////////////////
#ifndef DLog
	#ifdef DEBUG
	#	define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
	#else
	#	define DLog(...)
	#endif
#endif
