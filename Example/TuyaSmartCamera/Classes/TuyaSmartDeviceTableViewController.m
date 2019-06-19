//
//  TuyaSmartDeviceTableViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2018/12/24.
//  Copyright © 2018 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartDeviceTableViewController.h"
#import <TuyaSmartCameraKit/TuyaSmartCameraKit.h>
#import "TuyaSmartLoginManager.h"
#import "TuyaSmartDeviceManager.h"
#import <TuyaSmartHomeKit/TuyaSmartKit.h>
#import "TuyaSmartCameraViewController.h"

@interface TuyaSmartDeviceTableViewController ()

@property (nonatomic, strong) NSArray<TuyaSmartDeviceModel *> *dataSource;

@end

@implementation TuyaSmartDeviceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设备列表";
    
    [self doLogin:^{
        [[TuyaSmartDeviceManager sharedManager] getAllDevice];
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"deviceDidUpdate" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)doLogin:(void(^)(void))complete {
    NSString *countryCode = [TuyaSmartUserConfig countryCode];
    NSString *phoneNumer = [TuyaSmartUserConfig phoneNumber];
    NSString *email = [TuyaSmartUserConfig email];
    NSString *uid = [TuyaSmartUserConfig uid];
    NSString *password = [TuyaSmartUserConfig password];
    if (uid.length > 0) {
        [TuyaSmartLoginManager loginByUid:countryCode uid:uid password:password complete:^(NSError * _Nonnull error) {
            if (error) {
                NSLog(@"login error: %@", error);
            }
            !complete?:complete();
        }];
    }
    else if (phoneNumer.length > 0) {
        [TuyaSmartLoginManager loginByPhone:countryCode phoneNumber:phoneNumer password:password complete:^(NSError * _Nonnull error) {
            if (error) {
                NSLog(@"login error: %@", error);
            }
            !complete?:complete();
        }];
    }
    else if (email.length > 0) {
        [TuyaSmartLoginManager loginByEmail:countryCode email:email password:password complete:^(NSError * _Nonnull error) {
            if (error) {
                NSLog(@"login error: %@", error);
            }
            !complete?:complete();
        }];
    }
}

#pragma mark - private

- (void)reloadData {
    _dataSource = [TuyaSmartDeviceManager sharedManager].deviceList;
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cameraDevice"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cameraDevice"];
    }
    TuyaSmartDeviceModel *deviceModel = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = deviceModel.name;
    cell.detailTextLabel.text = deviceModel.isOnline ? @"online" : @"offline";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TuyaSmartDeviceModel *deviceMode = [self.dataSource objectAtIndex:indexPath.row];
    
    TuyaSmartCameraViewController *cameraVC = [[TuyaSmartCameraViewController alloc] initWithDeviceId:deviceMode.devId];
    [self.navigationController pushViewController:cameraVC animated:YES];
}



@end
