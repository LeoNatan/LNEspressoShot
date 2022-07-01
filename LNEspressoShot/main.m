//
//  main.m
//  LNTiffConverter
//
//  Created by Leo Natan on 7/1/22.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

static AppDelegate* _appDelegate;

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		_appDelegate = [AppDelegate new];
		NSApplication.sharedApplication.delegate = _appDelegate;
	}
	return NSApplicationMain(argc, argv);
}
