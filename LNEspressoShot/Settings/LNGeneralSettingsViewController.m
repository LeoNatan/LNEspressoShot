//
//  LNGeneralSettingsViewController.m
//  LNTiffConverter
//
//  Created by Leo Natan on 18/04/2023.
//

#import "LNGeneralSettingsViewController.h"
#import "CCNPreferencesWindowControllerProtocol.h"

@interface LNGeneralSettingsViewController () <CCNPreferencesWindowControllerProtocol>

@end

@implementation LNGeneralSettingsViewController

- (NSString *)preferenceIdentifier
{
	return @"General";
}

- (NSString *)preferenceTitle
{
	return @"General";
}

- (NSImage *)preferenceIcon
{
	return [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:nil];
}

@end
