//
//  AppDelegate.m
//  LNTiffConverter
//
//  Created by Leo Natan on 7/1/22.
//

#import "AppDelegate.h"
#import "LNSettingsWindowController.h"
#import "AdminShotHelper.h"

#import <ServiceManagement/ServiceManagement.h>
#import <Admin_Shot-Swift.h>

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
	_statusItem.menu = self._menu;
	[_statusItem.button sendActionOn:NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskRightMouseDown | NSEventMaskRightMouseUp];

	[self _updateStatusItemButtonImage];
	
	[_statusItem addObserver:self forKeyPath:@"appearance" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];

    NSError* err;
    SMAppService* service = [SMAppService daemonServiceWithPlistName:@"com.LeoNatan.AdminShotHelper.plist"];

    [service unregisterAndReturnError:&err];

    service = [SMAppService daemonServiceWithPlistName:@"com.LeoNatan.AdminShotHelper.plist"];

    int retryCount = 3;

    while(retryCount > 0)
    {
        retryCount--;

        __block BOOL rv = [service registerAndReturnError:&err];

        if(rv == NO)
        {
            NSLog(@"SMAppService error: %@", err.localizedDescription);
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate.date dateByAddingTimeInterval:0.5]];
            continue;
        }

        [self _scheduleTimer];

        return;
    }

    [[NSAlert alertWithError:err] runModal];
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
    if(LNUserCheck.isUserAdmin == YES)
	{
		return [NSImage imageNamed:@"enabled"];
	}
	else
	{
		return [NSImage imageNamed:@"disabled"];
	}
}

- (void)_updateStatusItemButtonImage
{
	_statusItem.button.image = self._imageForCurrentState;
}

- (NSMenu*)_menu
{
	NSMenu* menu = [NSMenu new];
	menu.autoenablesItems = NO;
	menu.delegate = self;
	
	NSMenuItem* automaticallyLaunchMenuItem = [menu addItemWithTitle:@"Start at Login" action:@selector(_launchAtLogin:) keyEquivalent:@""];
    automaticallyLaunchMenuItem.image = [NSImage imageWithSystemSymbolName:@"autostartstop" accessibilityDescription:nil];
	automaticallyLaunchMenuItem.state = [NSUserDefaults.standardUserDefaults boolForKey:LNAutomaticallyLaunchKey] ? NSControlStateValueOn : NSControlStateValueOff;
	
	[menu addItem:NSMenuItem.separatorItem];

    NSMenuItem* settings = [menu addItemWithTitle:@"Settings…" action:@selector(showSettings:) keyEquivalent:@","];
    settings.image = [NSImage imageWithSystemSymbolName:@"gear" accessibilityDescription:nil];
	settings.keyEquivalentModifierMask = NSEventModifierFlagCommand;

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

static NSTimer* _timer;
- (void)_scheduleTimer
{
    [_timer invalidate];
    _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(_timerTick) userInfo:nil repeats:NO];
    [NSRunLoop.currentRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)_timerTick
{
    [self _logic];
    [self _scheduleTimer];
}

- (void)_logic
{
    [self _updateStatusItemButtonImage];
    if(LNUserCheck.isUserAdmin == NO)
    {
        NSXPCConnection* connection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.LeoNatan.AdminShotHelper.xpc" options:NSXPCConnectionPrivileged];
        connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AdminShotHelperProtocol)];
        [connection resume];

        id<AdminShotHelperProtocol> proxy = [connection synchronousRemoteObjectProxyWithErrorHandler:^(NSError* error) {
            NSLog(@"XPC invalidated with error: %@", error);
        }];

        NSLog(@"Requesting help for user %@", NSUserName());

        [proxy helpWithUser:NSUserName() completionHandler:^{
            NSLog(@"Helper XPC finished");
        }];
    }
}

@end
