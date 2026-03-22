//
//  main.m
//  AdminShotHelper
//
//  Created by Léo Natan on 22/03/2026.
//

#import <Foundation/Foundation.h>
#import "AdminShotHelper.h"

@interface XPCListener : NSObject <NSXPCListenerDelegate, AdminShotHelperProtocol> @end
@implementation XPCListener
{
    NSXPCListener* _listener;
}

- (void)start
{
    _listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.LeoNatan.AdminShotHelper.xpc"];
    _listener.delegate = self;
    [_listener resume];

    dispatch_main();
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AdminShotHelperProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];

    return YES;
}

- (void)helpWithUser:(NSString *)user completionHandler:(void (^)(void))completionHandler
{
    NSTask* _coffee = [NSTask new];
    _coffee.executableURL = [NSURL fileURLWithPath:@"/usr/sbin/dseditgroup"];
    _coffee.arguments = @[
        @"-o",
        @"edit",
        @"-a",
        user,
        @"-t",
        @"user",
        @"admin"
    ];
    [_coffee launch];
    [_coffee waitUntilExit];

    completionHandler();
}

@end

int main(int argc, const char * argv[])
{
    [[XPCListener new] start];
}
