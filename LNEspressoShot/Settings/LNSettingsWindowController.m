//
//  LNSettingsWindowController.m
//  LNTiffConverter
//
//  Created by Leo Natan on 18/04/2023.
//

#import "LNSettingsWindowController.h"

@implementation LNSettingsWindowController

- (void)showPreferencesWindow
{
	if([self.window isVisible])
	{
		[NSApp activateIgnoringOtherApps:YES];
		[self.window makeKeyAndOrderFront:nil];
		
		return;
	}
	
	if(self.window == nil)
	{
		[self loadWindow];
	}
	
	if(self.viewControllers.count == 0)
	{
		NSStoryboard* sb = [NSStoryboard storyboardWithName:@"Settings" bundle:nil];
		
		[self setPreferencesViewControllers:@[[sb instantiateControllerWithIdentifier:@"General"]]];
	}
	
	self.centerToolbarItems = NO;
	
	if (@available(macOS 11.0, *))
	{
		self.window.toolbarStyle = NSWindowToolbarStylePreference;
	}
	self.window.styleMask &= ~NSWindowStyleMaskMiniaturizable;
	
	[NSApp activateIgnoringOtherApps:YES];
	[super showPreferencesWindow];
	
	[self.window center];
}

@end
