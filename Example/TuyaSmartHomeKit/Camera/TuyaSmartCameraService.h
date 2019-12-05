//
//  TuyaSmartCameraService.h
//  TYCameraLibrary
//
//  Created by 傅浪 on 2018/9/19.
//  Copyright © 2018 TuyaSmart. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuyaSmartCameraService : NSObject

+ (instancetype)sharedService;

- (NSInteger)definitionForCamera:(NSString *)devId;

- (void)setDefinition:(NSInteger)definition forCamera:(NSString *)devId;

- (NSInteger)audioModeForCamera:(NSString *)devId;

- (void)setAudioMode:(NSInteger)mode forCamera:(NSString *)devId;
    
- (BOOL)couldChangeAudioMode:(NSString *)devId;

- (void)setCouldChangedAudioMode:(BOOL)couldChange forCamera:(NSString *)devId;

@end
