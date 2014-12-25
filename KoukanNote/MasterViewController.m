//
//  MasterViewController.m
//  aaa
//
//  Created by 井上ユカリ on 2014/09/20.
//  Copyright (c) 2014年 YukariInoue. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "SVProgressHUD.h"

#import <Parse/Parse.h>


@interface MasterViewController ()
<UIAlertViewDelegate>
{
    NSMutableArray *_objects;
}
@end


@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //チャンネル用配列を初期化
    if (!_objects) {
        _objects=[NSMutableArray array];
    }
    
    //MARK:登録済みのチャンネルを取得
    _objects = (NSMutableArray *)[PFInstallation currentInstallation].channels;
    
    //追加ボタン
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;

    //背景画像
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"IMG_4270.png"]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)insertNewObject:(id)sender
{
    [self addPINCode];
}

#pragma mark - Add RoomName

- (void)addPINCode{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"新規作成" message:@"日記の名前を決めて下さい" delegate:self cancelButtonTitle:@"キャンセル" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}


#pragma mark - AlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            NSLog(@"Dismissed Alert");
            break;
        case 1:
        {
            if ([[alertView textFieldAtIndex:0].text length] < 1){
                [SVProgressHUD showErrorWithStatus:@"文字数が不足しています。"];
                [alertView textFieldAtIndex:0].text = nil;
            }else{
                [self checkString:alertView];
            }
        }
            break;
            
        default:
            break;
    }
    
}
    
- (void)checkString:(UIAlertView *)alertView
{
    NSError *err = nil;
    NSRegularExpression *regex = nil;
    
    // 記入された文字列を取得
    NSString *string = [alertView textFieldAtIndex:0].text;
    
    // 正規表現オブジェクト作成(英字のみ)
    regex = [NSRegularExpression
             regularExpressionWithPattern:@"([a-zA-Z]*)"
             options:NSRegularExpressionCaseInsensitive
             error:&err];
    
    // 比較
    NSTextCheckingResult *match = [regex firstMatchInString:string
                                                    options:0
                                                      range:NSMakeRange(0, string.length)];
    
    if (match) {
        NSRange matchRange = [match range];
        if (matchRange.length == string.length) {
            
            NSString *channelName = [alertView textFieldAtIndex:0].text;
            NSLog(@"Registered ChannnelName == %@", channelName);
            
            [PFPush subscribeToChannelInBackground:channelName block:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    
                    NSLog(@"登録に成功しました");
                    [PFPush sendPushMessageToChannel:channelName withMessage:@"チャンネル登録成功！" error:&error];
                    
                    if (!error) {
                        _objects = nil;
                        _objects = (NSMutableArray *)[PFInstallation currentInstallation].channels;
                        
                        [self.tableView reloadData];
                    }
                }
                else{
                    NSLog(@"%@の理由で登録に失敗しました", error);
                    [SVProgressHUD showErrorWithStatus:@"登録に失敗しました。"];
                    [alertView textFieldAtIndex:0].text = nil;
                    
                    //デバイストークンの再登録
                    //[PFPush storeDeviceToken:newDeviceToken];
                }
            }];
            
        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"入力エラー" message:@"日記名に使えるのは半角英字のみです。" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
        
    }
}


#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [_objects objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - TableView Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSURL *FURL=_objects[indexPath.row];//ファイルURLを取得
        NSFileManager *FManager=[NSFileManager defaultManager];
        if([FManager removeItemAtURL:FURL error:nil]){  //ファイルを削除
            //成功したらテーブルも削除
            [_objects removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}


#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
        
        DetailViewController *detailViewController = [segue destinationViewController];
        detailViewController.titleString = _objects[indexPath.row];
    }
}


-(IBAction)back{
    [self.navigationController popViewControllerAnimated:YES];
}



@end
