//
//  TYDownloadingProgressView.m
//  TYCameraPanelModule
//
//  Created by 傅浪 on 2019/12/13.
//

#import "TYDownloadingProgressView.h"
#import <DACircularProgress/DACircularProgressView.h>
#import "UIView+TPDemoAdditions.h"
#import "TPDemoUtils.h"
#import "TPDemoViewUtil.h"

UIKIT_EXTERN UIWindow *tp_mainWindow(void);

@interface TYDownloadingProgressView ()

@property (nonatomic, strong) UIView *rectView;

@property (nonatomic, strong) DACircularProgressView *progressView;

@property (nonatomic, strong) UILabel *progressLabel;

@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, assign) BOOL isHideProgressLabel;

@end

@implementation TYDownloadingProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [self addSubview:self.rectView];
        [self.rectView addSubview:self.progressView];
        [self.rectView addSubview:self.progressLabel];
        [self addSubview:self.cancelButton];
        [self.cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat contentHeight = self.rectView.height + self.cancelButton.height + 24;
    CGFloat top = (self.height - contentHeight) / 2;
    CGFloat centerX = self.width / 2;
    self.rectView.top = top;
    self.rectView.centerX = centerX;
    self.cancelButton.top = self.rectView.bottom + 24;
    self.cancelButton.centerX = centerX;
    
    [self.progressLabel sizeToFit];
    self.progressLabel.width = self.rectView.width;
    
    self.progressView.centerX = self.rectView.width / 2;
    self.progressLabel.centerX = self.rectView.width / 2;
    
    self.progressView.top = 30;
    self.progressLabel.top = self.progressView.bottom + 8;
    
    if (self.isHideProgressLabel) {
        self.progressView.top = 40;
        self.progressLabel.hidden = YES;
        [self.cancelButton setTitle:NSLocalizedString(@"ipc_confirm_cancel", @"") forState:UIControlStateNormal];
        
    }
}

- (void)cancelButtonAction {
    if (self.cancelAction) {
        self.cancelAction();
    }
}

- (void)show {
    [tp_mainWindow() addSubview:self];
}

- (void)hide {
    [self removeFromSuperview];
}

- (void)hideProgressLabel {
    self.isHideProgressLabel = YES;
}

- (void)setProgress:(NSInteger)progress {
    _progress = progress;
    self.progressView.progress = progress / 100.0;
    self.progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ipc_cloud_download_precent", @""), @(progress)];
}

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc] init];
        _progressLabel.font = [UIFont systemFontOfSize:14];
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ipc_cloud_download_precent", @""), @(100)];
    }
    return _progressLabel;
}

- (UIView *)rectView {
    if (!_rectView) {
        _rectView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
        _rectView.layer.cornerRadius = 8;
        _rectView.backgroundColor = [[TPDemoViewUtil colorWithHexString:@"#303030"] colorWithAlphaComponent:0.6];
    }
    return _rectView;
}

- (DACircularProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _progressView.roundedCorners = YES;
        _progressView.trackTintColor = [TPDemoViewUtil colorWithHexString:@"#535353"];
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.thicknessRatio = 0.1;
        _progressView.backgroundColor = [UIColor clearColor];
    }
    return _progressView;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setTitle:NSLocalizedString(@"ipc_confirm_cancel", @"") forState:UIControlStateNormal];
    }
    return _cancelButton;
}

@end
