//
//  AppDelegate.m
//  LNTiffConverter
//
//  Created by Leo Natan on 7/1/22.
//

#import "AppDelegate.h"
#import "LNSettingsWindowController.h"
#import <ServiceManagement/ServiceManagement.h>

@interface NSObject ()

+ (void)popUpStatusBarMenu:(id)arg1 ofItem:(id)arg2 ofBar:(id)arg3 inRect:(CGRect)arg4 ofView:(id)arg5 withEvent:(id)arg6;

@end

static NSString* const LNAutomaticallyLaunchKey = @"LNAutomaticallyLaunchKey";

@interface AppDelegate () <NSMenuDelegate>
{
	NSStatusItem* _statusItem;
	NSMenuItem* _enabledMenuItem;
	NSMenuItem* _automaticallyLaunchMenuItem;
	
	NSTask* _coffee;
	
	LNSettingsWindowController* _settingsWindowController;
}

@property (nonatomic, copy) NSURL* folderURL;

@end

@implementation AppDelegate

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		[NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:LNAutomaticallyLaunchKey options:0 context:NULL];
		
		_settingsWindowController = [LNSettingsWindowController new];
	}
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
	_statusItem.button.action = @selector(_toggle:);
	_statusItem.button.target = self;
	[_statusItem.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
	
	[self _updateStatusItemButtonImage];
	
	[_statusItem addObserver:self forKeyPath:@"appearance" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if([keyPath isEqualToString:@"appearance"])
	{
		[self _updateStatusItemButtonImage];
	}
	else if([keyPath isEqualToString:LNAutomaticallyLaunchKey])
	{
		[self _updateLaunchAtLoginState];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (NSImage*)_imageForCurrentState
{
	if(_coffee != nil)
	{
		return [NSImage imageNamed:@"enabled"];
	}
	else
	{
		return [NSImage imageNamed:@"disabled"];
	}
}

- (NSImageSymbolConfiguration*)_imageConfigurationForCurrentState
{
	if(_coffee != nil)
	{
		return [NSImageSymbolConfiguration configurationPreferringMonochrome];
	}
	
	return [NSImageSymbolConfiguration configurationWithHierarchicalColor:NSColor.textColor];
}

- (void)_updateStatusItemButtonImage
{
	_statusItem.button.image = [self._imageForCurrentState imageWithSymbolConfiguration:self._imageConfigurationForCurrentState];
}

- (NSMenu*)_menu
{
	NSMenu* menu = [NSMenu new];
	menu.autoenablesItems = NO;
	menu.delegate = self;
	
	NSMenuItem* enabledMenuItem = [menu addItemWithTitle:@"Enable" action:@selector(_toggleFromMenuItem:) keyEquivalent:@""];
	enabledMenuItem.state = _coffee != nil ? NSControlStateValueOn : NSControlStateValueOff;
	
	[menu addItem:NSMenuItem.separatorItem];
	
	NSMenuItem* automaticallyLaunchMenuItem = [menu addItemWithTitle:@"Start at Login" action:@selector(_launchAtLogin:) keyEquivalent:@""];
	automaticallyLaunchMenuItem.state = [NSUserDefaults.standardUserDefaults boolForKey:LNAutomaticallyLaunchKey] ? NSControlStateValueOn : NSControlStateValueOff;
	
	[menu addItem:NSMenuItem.separatorItem];
	
	[menu addItemWithTitle:@"Settings…" action:@selector(showSettings:) keyEquivalent:@","].keyEquivalentModifierMask = NSEventModifierFlagCommand;
	
	[menu addItem:NSMenuItem.separatorItem];
	
	[menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"].keyEquivalentModifierMask = NSEventModifierFlagCommand;
	
	return menu;
}

- (IBAction)showSettings:(id)sender
{
	[_settingsWindowController showPreferencesWindow];
}

- (void)_updateLaunchAtLoginState
{
	BOOL isEnabled = [NSUserDefaults.standardUserDefaults boolForKey:LNAutomaticallyLaunchKey];
	
	NSError* err = nil;
	SMAppService* appService = [SMAppService mainAppService];
	if(isEnabled)
	{
		if([appService registerAndReturnError:&err] == NO)
		{
			NSLog(@"Error enabling login item: %@", err);
		}
	}
	else
	{
		if([appService unregisterAndReturnError:&err] == NO)
		{
			NSLog(@"Error disabling login item: %@", err);
		}
	}
}

- (void)_launchAtLogin:(NSMenuItem*)sender
{
	[NSUserDefaults.standardUserDefaults setBool:![NSUserDefaults.standardUserDefaults boolForKey:LNAutomaticallyLaunchKey] forKey:LNAutomaticallyLaunchKey];
	
	[self _updateLaunchAtLoginState];
}

- (void)_toggleLogic
{
	if(_coffee)
	{
		if(_coffee.isRunning)
		{
			[_coffee terminate];
		}
		_coffee = nil;
	}
	else
	{
		_coffee = [NSTask new];
		_coffee.executableURL = [NSURL fileURLWithPath:@"/usr/bin/caffeinate"];
		_coffee.arguments = @[
			@"-d",
			@"-i",
			@"-u",
			@"-s",
			@"-w",
			@(getpid()).description
		];
		[_coffee launch];
	}
	[self _updateStatusItemButtonImage];
}

- (void)_toggleFromMenuItem:(NSMenuItem*)sender
{
	[self _toggleLogic];
}

- (void)_popMenu
{
	_statusItem.menu = self._menu;
	[_statusItem.button performClick:nil];
	_statusItem.menu = nil;
}

- (void)_toggle:(NSButton*)sender
{
	if(NSApp.currentEvent.type == NSEventTypeLeftMouseUp)
	{
		[self _toggleLogic];
	}
	else
	{
		[self _popMenu];
	}
}

@end
