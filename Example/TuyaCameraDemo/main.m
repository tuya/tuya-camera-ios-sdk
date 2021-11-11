//
//  main.m
//  TuyaCameraDemo
//
//  Created by 傅浪 on 2020/7/31.
//  Copyright © 2020 傅浪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
        
        // handle SIGPIPE
        struct sigaction sa;
        sa.sa_handler = SIG_IGN;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = 0;
        if (sigaction(SIGPIPE, &sa, NULL) < 0) {
            perror("cannot ignore SIGPIPE");
            return -1;
        }
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
