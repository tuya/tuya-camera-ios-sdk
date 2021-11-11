//
//  TYPlaybackImageDownloadManager.m
//  TuyaSmartDemo
//
//  Created by 傅浪 on 2020/7/20.
//

#import "TYPlaybackImageDownloadManager.h"

@interface TYPlaybackImageDownloadManager ()

@property (nonatomic, strong) TYPlaybackImageDownloadTask *head;

@property (nonatomic, strong) TYPlaybackImageDownloadTask *tail;

@end

@implementation TYPlaybackImageDownloadManager

- (void)downloadThumbnailsWithTimeSlice:(NSDictionary *)timeSlice filePath:(NSString *)filePath callback:(TYPlaybackImageDownloadCallback)callback {
    if (!callback) {
        return;
    }
    NSFileManager *fileManger = [NSFileManager defaultManager];
    if ([fileManger fileExistsAtPath:filePath]) {
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        callback(image, 0);
        return;
    }
    TYPlaybackImageDownloadTask *task = [TYPlaybackImageDownloadTask new];
    task.filePath = filePath;
    task.timeSlice = timeSlice;
    task.callback = callback;
    
    [self pushTask:task];
    [self execute];
}

- (void)pushTask:(TYPlaybackImageDownloadTask *)task {
    if (!task) {
        return;
    }
    if (!_head) {
        _head = task;
        _tail = task;
    }else {
        _tail.next = task;
        _tail = task;
    }
}

- (TYPlaybackImageDownloadTask *)popTask {
    if (!_head) {
        return nil;
    }
    TYPlaybackImageDownloadTask *task = _head;
    if (_head == _tail) {
        _head = nil;
        _tail = nil;
    }else {
        _head = _head.next;
    }
    return task;
}

- (void)execute {
    if (!_head || _head.isExecuting) {
        return;
    }
    _head.executing = YES;
    
    __weak typeof(self) weak_self = self;
    NSLog(@"&&& begin download: %@", _head.filePath.lastPathComponent);
    [self.camera downloadVideoThumbnailForSlice:_head.timeSlice filePath:_head.filePath success:^{
        [weak_self finished:0];
        NSLog(@"&&& download success");
    } failure:^(int errCode) {
        [weak_self finished:errCode];
        NSLog(@"&&& download failed: %@", @(errCode));
    }];
}

- (void)finished:(int)errCode {
    TYPlaybackImageDownloadTask *task = [self popTask];
    UIImage *image = nil;
    if (errCode == 0) {
        image = [UIImage imageWithContentsOfFile:task.filePath];
    }
    task.callback(image, errCode);
    [self execute];
}

@end

@implementation TYPlaybackImageDownloadTask



@end
