//
//  TuyaSmartCameraService.m
//  TYCameraLibrary
//
//  Created by 傅浪 on 2018/9/19.
//  Copyright © 2018 TuyaSmart. All rights reserved.
//

#import "TuyaSmartCameraService.h"
#import <pthread.h>
#import <TuyaSmartCameraBase/TYCameraUtil.h>

#define kDefaultCameraTwoWayTalk @"kDefaultCameraTwoWayTalk"
#define kDefaultCameraCouldChangeTalkMode @"kDefaultCameraCouldChangeTalkMode"
#define kDefaultCameraDefinition @"kDefaultCameraDefinition"
#define kDefaultCameraOutlineEnable @"kDefaultCameraOutlineEnable"

#define kTuyaDoorbellNotification @"kNotificationMQTTMessageNotification"

@interface TuyaSmartCameraService () {
    NSMutableDictionary *_cacheDict;
    NSMutableDictionary *_cacheDict2;
    NSMutableDictionary *_definitionCache;
    NSMutableDictionary *_outlineEnableCache;
    pthread_mutex_t _lock;
}

@end

@implementation TuyaSmartCameraService

+ (instancetype)sharedService {
    static dispatch_once_t onceToken;
    static TuyaSmartCameraService *_instance;
    dispatch_once(&onceToken, ^{
        _instance = [[TuyaSmartCameraService alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultCameraTwoWayTalk];
        NSDictionary *dict2 = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultCameraCouldChangeTalkMode];
        NSDictionary *dict3 = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultCameraDefinition];
        NSDictionary *dict4 = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultCameraOutlineEnable];
        _cacheDict = dict ? [dict mutableCopy] : [NSMutableDictionary new];
        _cacheDict2 = dict2 ? [dict2 mutableCopy] : [NSMutableDictionary new];
        _definitionCache = dict3 ? [dict3 mutableCopy] : [NSMutableDictionary new];
        _outlineEnableCache = dict4 ? [dict4 mutableCopy] : [NSMutableDictionary new];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (NSInteger)definitionForCamera:(NSString *)devId {
    if (devId.length == 0) {
        return 0;
    }
    NSString *key = [TYCameraUtil md5WithString:devId];
    pthread_mutex_lock(&_lock);
    NSNumber *definition = [_definitionCache objectForKey:key];
    pthread_mutex_unlock(&_lock);
    if (definition == nil) {
        return 0;
    }
    return [definition integerValue];
}

- (void)setDefinition:(NSInteger)definition forCamera:(NSString *)devId {
    if (devId.length == 0) {
        return;
    }
    NSString *key = [TYCameraUtil md5WithString:devId];
    pthread_mutex_lock(&_lock);
    [_definitionCache setObject:@(definition) forKey:key];
    pthread_mutex_unlock(&_lock);
    [[NSUserDefaults standardUserDefaults] setObject:[_definitionCache copy] forKey:kDefaultCameraDefinition];
}

- (NSInteger)audioModeForCamera:(NSString *)devId {
    if (devId.length == 0) { return 0; }
    NSString *key = [TYCameraUtil md5WithString:devId];
    pthread_mutex_lock(&_lock);
    NSNumber *mode = [_cacheDict objectForKey:key];
    pthread_mutex_unlock(&_lock);
    if (mode == nil) {
        return 0;
    }
    return [mode integerValue];
}

- (void)setAudioMode:(NSInteger)mode forCamera:(NSString *)devId {
    if (devId.length == 0) { return; }
    NSString *key = [TYCameraUtil md5WithString:devId];
    pthread_mutex_lock(&_lock);
    [_cacheDict setObject:@(mode) forKey:key];
    pthread_mutex_unlock(&_lock);
    [[NSUserDefaults standardUserDefaults] setObject:[_cacheDict copy] forKey:kDefaultCameraTwoWayTalk];
}

- (BOOL)couldChangeAudioMode:(NSString *)devId {
    if (devId.length == 0) return NO;
    NSString *key = [TYCameraUtil md5WithString:devId];
    pthread_mutex_lock(&_lock);
    NSNumber * couldChange = [_cacheDict2 objectForKey:key];
    pthread_mutex_unlock(&_lock);
    if (couldChange == nil) {
        return NO;
    }
    return [couldChange boolValue];
}

- (void)setCouldChangedAudioMode:(BOOL)couldChange forCamera:(NSString *)devId {
    if (devId.length == 0) return;
    NSString *key = [TYCameraUtil md5WithString:devId];
    pthread_mutex_lock(&_lock);
    [_cacheDict2 setObject:@(couldChange) forKey:key];
    pthread_mutex_unlock(&_lock);
    [[NSUserDefaults standardUserDefaults] setObject:[_cacheDict2 copy] forKey:kDefaultCameraCouldChangeTalkMode];
}

- (void)observeDoorbellCall:(void(^)(NSString *devId, NSString *type))callback {
    if (!callback) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserverForName:kTuyaDoorbellNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSDictionary *eventInfo = note.object;
        NSString *devId = eventInfo[@"devId"];
        NSString *eType = [eventInfo objectForKey:@"etype"];
        if ([eType isEqualToString:@"doorbell"]) {
            callback(devId, eType);
        }
    }];
}

- (void)removeAllThumbnailsForDevice:(NSString *)devId {
    NSString *directoryPath = [self thumbnailDirectoryForDevice:devId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:directoryPath]) {
        [fileManager removeItemAtPath:directoryPath error:nil];
    }
}


- (NSString *)thumbnailDirectoryForDevice:(NSString *)devId {
    NSString *key = [TYCameraUtil md5WithString:devId];
    NSString *directoryPath = [[self playbackThumbnailRootDirectory] stringByAppendingPathComponent:key];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:directoryPath]) {
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return directoryPath;
}

- (NSString *)playbackThumbnailRootDirectory {
    static NSString *_thumbnailsPath = nil;
    if (!_thumbnailsPath) {
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"TYCameraPlaybackThumbnails"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:directoryPath]) {
            [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        _thumbnailsPath = directoryPath;
    }
    return _thumbnailsPath;
}

@end
