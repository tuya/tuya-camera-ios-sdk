//
//  TYDownloadingProgressView.h
//  TYCameraPanelModule
//
//  Created by 傅浪 on 2019/12/13.
//

#import <UIKit/UIKit.h>

@interface TYDownloadingProgressView : UIView

@property (nonatomic, assign) NSInteger progress;

@property (nonatomic, copy) void(^cancelAction)(void);

- (void)show;

- (void)hide;

- (void)hideProgressLabel;

@end
