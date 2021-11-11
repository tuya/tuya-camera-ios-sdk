//
//  TYCameraCloudViewController.m
//  TuyaSmartHomeKit_Example
//
//  Created by 傅浪 on 2019/8/5.
//  Copyright © 2019 xuchengcheng. All rights reserved.
//

#import "TYDemoCameraCloudViewController.h"
#import "TYCloudDayCollectionViewCell.h"
#import "TYPermissionUtil.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <TuyaSmartCameraKit/TuyaSmartCameraKit.h>
#import <TYEncryptImage/TYEncryptImage.h>

#define TopBarHeight 88
#define VideoViewWidth [UIScreen mainScreen].bounds.size.width
#define VideoViewHeight ([UIScreen mainScreen].bounds.size.width / 16 * 9)

#define kControlRecord      @"record"
#define kControlPhoto       @"photo"

@interface TYDemoCameraCloudViewController ()<UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) TuyaSmartDevice *device;

@property (nonatomic, strong) TuyaSmartCloudManager *cloudManager;

@property (nonatomic, strong) TuyaSmartCloudDayModel *selectedDay;

@property (nonatomic, strong) NSArray *timePieces;

@property (nonatomic, strong) NSArray *eventModels;

@property (nonatomic, strong) UITableView *timePiecesTable;

@property (nonatomic, strong) UITableView *eventTable;

@property (nonatomic, strong) UICollectionView *dayCollectionView;

@property (nonatomic, strong) UIButton *switchButton;

@property (nonatomic, strong) UIButton *photoButton;

@property (nonatomic, strong) UIButton *recordButton;

@property (nonatomic, strong) UIButton *pauseButton;

@property (nonatomic, strong) UIButton *soundButton;

@property (nonatomic, strong) UIView *controlBar;

@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, assign) BOOL isPaused;

@end

@implementation TYDemoCameraCloudViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.device = [TuyaSmartDevice deviceWithDeviceId:self.devId];
    self.cloudManager = [[TuyaSmartCloudManager alloc] initWithDeviceId:self.devId];
    [self.cloudManager loadCloudData:^(TuyaSmartCloudState state) {
        [self.dayCollectionView reloadData];
        [self checkCloudState:state];
    }];
    self.topBarView.leftItem = self.leftBackItem;
    [self.view addSubview:self.cloudManager.videoView];
    [self.cloudManager.videoView tuya_clear];
    
    self.cloudManager.videoView.frame = CGRectMake(0, APP_TOP_BAR_HEIGHT, VideoViewWidth, VideoViewHeight);
    
    self.timePiecesTable = [[UITableView alloc] initWithFrame:CGRectMake(0, self.cloudManager.videoView.bottom + 50, APP_SCREEN_WIDTH, APP_SCREEN_HEIGHT - (self.cloudManager.videoView.bottom + 100))];
    self.timePiecesTable.delegate = self;
    self.timePiecesTable.dataSource = self;
    
    self.eventTable = [[UITableView alloc] initWithFrame:CGRectMake(0, self.cloudManager.videoView.bottom + 50, APP_SCREEN_WIDTH, APP_SCREEN_HEIGHT - (self.cloudManager.videoView.bottom + 100))];
    self.eventTable.delegate = self;
    self.eventTable.dataSource = self;
    self.eventTable.hidden = YES;
    [self.view addSubview:self.timePiecesTable];
    [self.view addSubview:self.eventTable];
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(80, 50);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    self.dayCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.cloudManager.videoView.bottom, APP_SCREEN_WIDTH - 80, 50) collectionViewLayout:layout];
    [self.view addSubview:self.dayCollectionView];
    self.dayCollectionView.delegate = self;
    self.dayCollectionView.dataSource = self;
    self.dayCollectionView.backgroundColor = [UIColor whiteColor];
    [self.dayCollectionView registerClass:[TYCloudDayCollectionViewCell class] forCellWithReuseIdentifier:@"cloudDay"];
    
    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.dayCollectionView.right, self.dayCollectionView.top, 80, 50)];
    [self.view addSubview:self.switchButton];
    [self.switchButton setTitle:NSLocalizedString(@"Switch Table", @"") forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(switchAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.soundButton];
    [self.view addSubview:self.controlBar];
    
    [self.soundButton addTarget:self action:@selector(soundAction) forControlEvents:UIControlEventTouchUpInside];
    [self.photoButton addTarget:self action:@selector(photoAction) forControlEvents:UIControlEventTouchUpInside];
    [self.recordButton addTarget:self action:@selector(recordAction) forControlEvents:UIControlEventTouchUpInside];
    [self.pauseButton addTarget:self action:@selector(pauseAction) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)switchAction {
    self.timePiecesTable.hidden = !self.timePiecesTable.hidden;
    self.eventTable.hidden = !self.eventTable.hidden;
}

- (void)soundAction {
    BOOL isMuted = [self.cloudManager isMuted];
    __weak typeof(self) weakSelf = self;
    [self.cloudManager enableMute:!isMuted success:^{
        NSString *imageName = @"ty_camera_soundOn_icon";
        if (weakSelf.cloudManager.isMuted) {
            imageName = @"ty_camera_soundOff_icon";
        }
        [self.soundButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        NSLog(@"enable mute success");
    } failure:^(NSError *error) {
        [self alertWithMessage:NSLocalizedString(@"enable mute failed", @"")];
    }];
}

- (void)recordAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            if (self.isRecording) {
                self.isRecording = NO;
                self.recordButton.tintColor = [UIColor blackColor];
                if ([self.cloudManager stopRecord] != 0) {
                    [self alertWithMessage:NSLocalizedString(@"record failed", @"")];
                }else {
                    [self alertWithMessage:NSLocalizedString(@"ipc_multi_view_video_saved", @"")];
                }
            }else {
                [self.cloudManager startRecord];
                self.isRecording = YES;
                self.recordButton.tintColor = [UIColor redColor];
            }
        }
    }];
}

- (void)pauseAction {
    if (self.isPlaying && self.isPaused) {
        if ([self.cloudManager resumePlayCloudVideo]) {
            [self alertWithMessage:NSLocalizedString(@"fail", @"")];
        }else {
            UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_pause_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.pauseButton setImage:image forState:UIControlStateNormal];
            self.isPaused = NO;
        }
    }else if (self.isPlaying) {
        if ([self.cloudManager pausePlayCloudVideo]) {
            [self alertWithMessage:NSLocalizedString(@"fail", @"")];
        }else {
            UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_play_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.pauseButton setImage:image forState:UIControlStateNormal];
            self.isPaused = YES;
        }
    }
}

- (void)photoAction {
    [self checkPhotoPermision:^(BOOL result) {
        if (result) {
            if ([self.cloudManager snapShoot]) {
                [self alertWithMessage:NSLocalizedString(@"ipc_multi_view_photo_saved", @"")];
            }else {
                [self alertWithMessage:NSLocalizedString(@"fail", @"")];
            }
        }
    }];
}


- (NSString *)titleForCenterItem {
    return NSLocalizedString(@"ipc_panel_button_cstorage", @"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.topBarView.hidden = NO;
    self.navigationController.navigationBar.hidden = YES;
}

- (void)checkCloudState:(TuyaSmartCloudState)state {
    switch (state) {
        case TuyaSmartCloudStateNoService:
            [self gotoCloudServicePanel];
            [self alertWithMessage:NSLocalizedString(@"ipc_cloudstorage_status_off", @"")];
            break;
        case TuyaSmartCloudStateNoData:
        case TuyaSmartCloudStateExpiredNoData:
            [self alertWithMessage:NSLocalizedString(@"ipc_cloudstorage_noDataTips", @"")];
            break;
        case TuyaSmartCloudStateLoadFailed:
            [self alertWithMessage:NSLocalizedString(@"ty_network_error", @"")];
            break;
        case TuyaSmartCloudStateValidData:
        case TuyaSmartCloudStateExpiredData:
            [self.dayCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionLeft];
            [self loadTimePieceForDay:self.cloudManager.cloudDays.firstObject];
        default:
            break;
    }
}

- (void)loadTimePieceForDay:(TuyaSmartCloudDayModel *)dayModel {
    self.selectedDay = dayModel;
    [self.cloudManager timeLineWithCloudDay:dayModel success:^(NSArray<TuyaSmartCloudTimePieceModel *> *timePieces) {
        self.timePieces = timePieces;
        [self.timePiecesTable reloadData];
        [self playCloudTimePiece:self.timePieces.firstObject];
    } failure:^(NSError *error) {
        [self alertWithMessage:NSLocalizedString(@"ipc_errormsg_data_load_failed", @"")];
    }];
    [self.cloudManager timeEventsWithCloudDay:dayModel offset:0 limit:-1 success:^(NSArray<TuyaSmartCloudTimeEventModel *> *timeEvents) {
        self.eventModels = timeEvents;
        [self.eventTable reloadData];
    } failure:^(NSError *error) {
        [self alertWithMessage:NSLocalizedString(@"ipc_errormsg_data_load_failed", @"")];
    }];
}

- (void)gotoCloudServicePanel {
//    [TYCameraCloudServicePanelSDK cloudServicePanelWithDevice:self.device.deviceModel success:^(UIViewController * _Nonnull vc) {
//        self.topBarView.hidden = YES;
//        self.navigationController.navigationBar.hidden = NO;
////        [self.navigationController pushViewController:vc animated:YES];
//        UINavigationController *navi = (UINavigationController *)vc;
//        navi.topViewController.modalPresentationStyle = UIModalPresentationFullScreen;
//        vc.modalPresentationStyle = UIModalPresentationFullScreen;
//        [self presentViewController:vc animated:YES completion:nil];
//    } failure:^(NSError * _Nonnull error) {
//        [self alertWithMessage:@"加载失败"];
//    }];
}

- (void)alertWithMessage:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:confirm];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)playCloudTimePiece:(TuyaSmartCloudTimePieceModel *)pieceModel {
    if (!pieceModel) return;
    __weak typeof(self) weakSelf = self;
    [self.cloudManager playCloudVideoWithStartTime:pieceModel.startTime endTime:self.selectedDay.endTime isEvent:NO onResponse:^(int errCode) {
        if (errCode) {
            [weakSelf alertWithMessage:NSLocalizedString(@"ipc_status_stream_failed", @"")];
        }else {
            self.isPlaying = YES;
            self.isPaused = NO;
        }
    } onFinished:^(int errCode) {
        [weakSelf alertWithMessage:NSLocalizedString(@"ipc_video_end", @"")];
    }];
}

- (void)playCloudEvent:(TuyaSmartCloudTimeEventModel *)eventModel {
    __weak typeof(self) weakSelf = self;
    [self.cloudManager playCloudVideoWithStartTime:eventModel.startTime endTime:self.selectedDay.endTime isEvent:YES onResponse:^(int errCode) {
        if (errCode) {
            [weakSelf alertWithMessage:NSLocalizedString(@"ipc_status_stream_failed", @"")];
        }else {
            self.isPlaying = YES;
            self.isPaused = NO;
        }
    } onFinished:^(int errCode) {
        [weakSelf alertWithMessage:NSLocalizedString(@"ipc_video_end", @"")];
    }];
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.timePiecesTable) {
        return self.timePieces.count;
    }
    if (tableView == self.eventTable) {
        return self.eventModels.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
    });
    if (tableView == self.timePiecesTable) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timePieces"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"timePieces"];
        }
        TuyaSmartCloudTimePieceModel *pieceModel = [self.timePieces objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@-%@", [formatter stringFromDate:pieceModel.startDate], [formatter stringFromDate:pieceModel.endDate]];
        return cell;
    }else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"event"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"event"];
        }
        TuyaSmartCloudTimeEventModel *eventModel = [self.eventModels objectAtIndex:indexPath.row];
        [cell.imageView ty_setAESImageWithPath:eventModel.snapshotUrl encryptKey:self.cloudManager.encryptKey placeholderImage:[self placeholder]];
        cell.textLabel.text = eventModel.describe;
        cell.detailTextLabel.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:eventModel.startTime]];
        return cell;
    }
}

- (UIImage *)placeholder {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContext(CGSizeMake(88, 50));
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return image;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.timePiecesTable) {
        TuyaSmartCloudTimePieceModel *pieceModel = [self.timePieces objectAtIndex:indexPath.row];
        [self playCloudTimePiece:pieceModel];
    }else {
        TuyaSmartCloudTimeEventModel *eventModel = [self.eventModels objectAtIndex:indexPath.row];
        [self playCloudEvent:eventModel];
    }
}

#pragma mark - collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cloudManager.cloudDays.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TYCloudDayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cloudDay" forIndexPath:indexPath];
    TuyaSmartCloudDayModel *dayModel = [self.cloudManager.cloudDays objectAtIndex:indexPath.item];
    cell.textLabel.text = dayModel.uploadDay;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TuyaSmartCloudDayModel *dayModel = [self.cloudManager.cloudDays objectAtIndex:indexPath.row];
    [self loadTimePieceForDay:dayModel];
}

- (UIButton *)soundButton {
    if (!_soundButton) {
        _soundButton = [[UIButton alloc] initWithFrame:CGRectMake(8, TopBarHeight + VideoViewHeight - 50, 44, 44)];
        [_soundButton setImage:[UIImage imageNamed:@"ty_camera_soundOff_icon"] forState:UIControlStateNormal];
    }
    return _soundButton;
}

- (UIButton *)photoButton {
    if (!_photoButton) {
        _photoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_photo_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_photoButton setImage:image forState:UIControlStateNormal];
        [_photoButton setTintColor:[UIColor blackColor]];
    }
    return _photoButton;
}

- (UIButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_rec_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_recordButton setImage:image forState:UIControlStateNormal];
        [_recordButton setTintColor:[UIColor blackColor]];
    }
    return _recordButton;
}

- (UIButton *)pauseButton {
    if (!_pauseButton) {
        _pauseButton = [[UIButton alloc] init];
        UIImage *image = [[UIImage imageNamed:@"ty_camera_tool_pause_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_pauseButton setImage:image forState:UIControlStateNormal];
        [_pauseButton setTintColor:[UIColor blackColor]];
    }
    return _pauseButton;
}

- (UIView *)controlBar {
    if (!_controlBar) {
        _controlBar = [[UIView alloc] initWithFrame:CGRectMake(0, APP_SCREEN_HEIGHT - 50, VideoViewWidth, 50)];
        [_controlBar addSubview:self.photoButton];
        [_controlBar addSubview:self.pauseButton];
        [_controlBar addSubview:self.recordButton];
        CGFloat width = VideoViewWidth / 3;
        [_controlBar.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
            obj.frame = CGRectMake(width * idx, 0, width, 50);
        }];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, VideoViewWidth, 0.5)];
        line.backgroundColor = [UIColor lightGrayColor];
        [_controlBar addSubview:line];
    }
    return _controlBar;
}

- (void)checkPhotoPermision:(void(^)(BOOL result))complete {
    if ([TYPermissionUtil isPhotoLibraryNotDetermined]) {
        [TYPermissionUtil requestPhotoPermission:complete];
    }else if ([TYPermissionUtil isPhotoLibraryDenied]) {
        [self alertWithMessage:NSLocalizedString(@"Photo library permission denied", @"")];
        !complete?:complete(NO);
    }else {
        !complete?:complete(YES);
    }
}

@end
