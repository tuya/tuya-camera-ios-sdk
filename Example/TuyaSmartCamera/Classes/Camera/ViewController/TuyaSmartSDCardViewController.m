//
//  TuyaSmartSDCardViewController.m
//  TuyaSmartCamera_Example
//
//  Created by 傅浪 on 2019/3/21.
//  Copyright © 2019 fulang@tuya.com. All rights reserved.
//

#import "TuyaSmartSDCardViewController.h"

#define kTitle  @"title"
#define kValue  @"value"

@interface TuyaSmartSDCardViewController ()<TuyaSmartCameraDPObserver>

@property (nonatomic, assign) NSInteger total;
@property (nonatomic, assign) NSInteger used;
@property (nonatomic, assign) NSInteger left;

@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) UIButton *formatButton;

@end

@implementation TuyaSmartSDCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WEAKSELF_AT
    [self.dpManager valueForDP:TuyaSmartCameraSDCardStorageDPName success:^(id result) {
        NSArray *components = [result componentsSeparatedByString:@"|"];
        if (components.count < 3) {
            return;
        }
        weakSelf_AT.total = [[components firstObject] integerValue];
        weakSelf_AT.used = [[components objectAtIndex:1] integerValue];
        weakSelf_AT.left = [[components lastObject] integerValue];
        [weakSelf_AT reloadData];
    } failure:^(NSError *error) {
        
    }];
    
    UIButton *formatButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    [formatButton addTarget:self action:@selector(formatAction) forControlEvents:UIControlEventTouchUpInside];
    [formatButton setTitle:@"格式化SD卡" forState:UIControlStateNormal];
    [formatButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.tableView.tableFooterView = formatButton;
    self.formatButton = formatButton;
    
    [self.dpManager addObserver:self];
    
}

- (void)formatAction {
    self.formatButton.enabled = NO;
    [self.dpManager setValue:@(YES) forDP:TuyaSmartCameraSDCardFormatDPName success:^(id result) {
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)reloadData {
    NSMutableArray *dataSource = [NSMutableArray new];
    NSMutableArray *section0 = [NSMutableArray new];
    NSString *totalText = [NSString stringWithFormat:@"%.1fG", self.total / 1024.0 / 1024.0];
    NSString *usedText = [NSString stringWithFormat:@"%.1fG", self.used / 1024.0 / 1024.0];
    NSString *leftText = [NSString stringWithFormat:@"%.1fG", self.left / 1024.0 / 1024.0];
    [section0 addObject:@{kTitle: @"总容量", kValue: totalText}];
    [section0 addObject:@{kTitle: @"已使用", kValue: usedText}];
    [section0 addObject:@{kTitle: @"剩余容量", kValue: leftText}];
    
    [dataSource addObject:@{kTitle: @"SD卡容量", kValue: section0.copy}];
    self.dataSource = [dataSource copy];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.dataSource objectAtIndex:section] objectForKey:kValue] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [[[self.dataSource objectAtIndex:indexPath.section] objectForKey:kValue] objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [data objectForKey:kTitle];
    cell.detailTextLabel.text = [data objectForKey:kValue];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.dataSource objectAtIndex:section] objectForKey:kTitle];
}

- (void)cameraDPDidUpdate:(TuyaSmartCameraDPManager *)manager dps:(NSDictionary *)dpsData {
    if ([dpsData objectForKey:TuyaSmartCameraSDCardFormatStateDPName]) {
        NSInteger progress = [[dpsData objectForKey:TuyaSmartCameraSDCardFormatStateDPName] intValue];
        if (progress == 100) {
            self.formatButton.enabled = YES;
            NSLog(@"&&&& sd card format success");
        }
        if (progress < 0) {
            self.formatButton.enabled = YES;
            NSLog(@"&&&& sd card format failure");
        }
        NSLog(@"&&&& sd card formatting progress: %@%%", [dpsData objectForKey:TuyaSmartCameraSDCardFormatStateDPName]);
    }
}

@end
