//
//  TYPlaybackImageDownloadManager.h
//  TuyaSmartDemo
//
//  Created by 傅浪 on 2020/7/20.
//

#import <Foundation/Foundation.h>
#import "TuyaSmartCamera.h"

@interface TYPlaybackImageDownloadTask : NSObject

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, strong) NSDictionary *timeSlice;

@property (nonatomic, copy) TYPlaybackImageDownloadCallback callback;

@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@property (nonatomic, strong) TYPlaybackImageDownloadTask *next;

@end

@interface TYPlaybackImageDownloadManager : NSObject

@property (nonatomic, weak) id<TuyaSmartCameraType> camera;

- (void)downloadThumbnailsWithTimeSlice:(NSDictionary *)timeSlice filePath:(NSString *)filePath callback:(TYPlaybackImageDownloadCallback)callback;

@end


