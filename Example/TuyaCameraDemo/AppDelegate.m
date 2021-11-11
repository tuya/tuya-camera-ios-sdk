//
//  AppDelegate.m
//  TuyaCameraDemo
//
//  Created by 傅浪 on 2020/7/31.
//  Copyright © 2020 傅浪. All rights reserved.
//

#import "AppDelegate.h"
#import "TYDemoApplicationImpl.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    TYDemoConfigModel *config = [[TYDemoConfigModel alloc] init];
    // config your appkey and secret
    config.appKey = <#your appkey#>;
    config.secretKey = <#your appSecret#>;
    
    return [[TYDemoApplicationImpl sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions config:config];
}

#pragma mark - Forward
- (id)forwardingTargetForSelector:(SEL)aSelector {
    id impl = [TYDemoApplicationImpl sharedInstance];
    if ([impl respondsToSelector:aSelector]) {
        return impl;
    }

    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector]
    || [[TYDemoApplicationImpl sharedInstance] respondsToSelector:aSelector];
}

@end
