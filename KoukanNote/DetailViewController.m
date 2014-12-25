//
//  DetailViewController.m
//  aaa
//
//  Created by 井上ユカリ on 2014/09/20.
//  Copyright (c) 2014年 YukariInoue. All rights reserved.
//

#import "DetailViewController.h"
#import "SVProgressHUD.h"

#import <Parse/Parse.h>

@interface DetailViewController ()
<UITextViewDelegate,UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextView *contentField;


- (void)configureView;
-(IBAction)plus;

@end



@implementation DetailViewController

{
    IBOutlet UIImageView *imageView;
    IBOutlet UITableView *tableView;
    
    NSMutableArray *imageArray;
    NSMutableArray *titleArray;
    NSMutableArray *detailTextArray;
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    self.navigationItem.title = self.titleString;
    
    self.titleField.delegate = self;
    self.titleField.tag = 1;
    self.contentField.delegate = self;
    self.contentField.returnKeyType = UIReturnKeyDone;
    self.contentField.tag = 2;
    
    if (!titleArray) {
        titleArray = [[NSMutableArray alloc] init];
    }
    
    if (!imageArray) {
        imageArray = [[NSMutableArray alloc] init];
    }
    
    
    if (!detailTextArray) {
        detailTextArray = [[NSMutableArray alloc] init];
    }
    
    tableView.delegate = self;
    tableView.dataSource = self;
    
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [self loadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)plus{
    UIImagePickerController *ipc =[[UIImagePickerController alloc]init];
    [ipc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [ipc setDelegate:self];
    [ipc setAllowsEditing:YES];
    [self presentViewController:ipc animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image=[info objectForKey:UIImagePickerControllerEditedImage];
    [imageView setImage:image];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
    // 画像をNSUserDefaultsへ保存する
    NSData *imageData = UIImagePNGRepresentation(image);
    [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:self.titleField.text];
    if (![[NSUserDefaults standardUserDefaults] synchronize] ) {
        NSLog(@"error!");
    }

}

#pragma mark - Text Field
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [self.titleField resignFirstResponder];
    
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"]) {
        // ここにtextのデータ(記録)処理など
        // キーボードを閉じる
        [self.contentField resignFirstResponder];
        return NO;
    }
    return YES;
}

#pragma mark - Save
- (IBAction)saveData
{
    UIImage *postImage = nil;
    if (!imageView.image) {
        postImage = [UIImage imageNamed:@"noimage.jpg"];
    }else{
        postImage = imageView.image;
    }
    
    NSData *pngData = [[NSData alloc] initWithData:UIImagePNGRepresentation(postImage)];
    NSString *dateString = @"photo";
    PFFile *file = [PFFile fileWithName:dateString data:pngData];
    
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (succeeded) {
            NSLog(@"fileの保存に成功");
            
            [SVProgressHUD showSuccessWithStatus:@"投稿成功！"];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            NSLog(@"fileの保存に%@の理由で失敗", error.description);
        }
    } progressBlock:^(int progress){
        //UIKitはメインスレッドに戻してあげる
        dispatch_async(dispatch_get_main_queue(),^{
            [SVProgressHUD showWithStatus:@"保存中..." maskType:SVProgressHUDMaskTypeBlack];
            NSLog(@"progress ... %d", progress);
        });
    }];
    
    NSString *className = @"Note";
    NSString *channelName = self.navigationItem.title;
    
    PFObject *postObject = [PFObject objectWithClassName:className];
    postObject[@"title"] = self.titleField.text;
    postObject[@"content"] = self.contentField.text;
    postObject[@"image"] = file;
    postObject[@"roomCode"] = channelName;//FIXME:部屋名をきめる
    
    [postObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"postObjectの保存に成功");
            
            NSString *messageString = [NSString stringWithFormat:@"%@が更新されました。", className];
            NSError *error;
            [PFPush sendPushMessageToChannel:channelName withMessage:messageString error:&error];
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"通知エラー" message:[NSString stringWithFormat:@"%@が原因で送信できませんでした。", error.description] delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                
                NSLog(@"error == %@", error.description);
            }
            
            
        } else {
            NSLog(@"postObjectの保存に%@の理由で失敗", error.description);
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"保存エラー" message:[NSString stringWithFormat:@"%@が原因で保存できませんでした。", error.description] delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
                
                NSLog(@"error == %@", error.description);
            }
        }
    }];
}



// アスペクト比を保ってUIImageをリサイズ
- (UIImage *)resizeAspectFitWithSize:(UIImage *)srcImg size:(CGSize)size {
    
    CGFloat widthRatio  = size.width  / srcImg.size.width;
    CGFloat heightRatio = size.height / srcImg.size.height;
    CGFloat ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio;
    
    CGSize resizedSize = CGSizeMake(srcImg.size.width*ratio, srcImg.size.height*ratio);
    
    UIGraphicsBeginImageContext(resizedSize);
    [srcImg drawInRect:CGRectMake(0, 0, resizedSize.width, resizedSize.height)];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

#pragma mark - TableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return titleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //セルの生成
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.imageView.image = [imageArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [titleArray objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [detailTextArray objectAtIndex:indexPath.row];
    return cell;
}


#pragma mark - loadData

- (void)loadData
{
    NSArray *channelArray = [PFInstallation currentInstallation].channels;
    if (channelArray.count < 1) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"登録エラー" message:@"登録に失敗しました。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
    
    // Data Load
    PFQuery *query = [PFQuery queryWithClassName:@"Note"];
    
    [query whereKey:@"roomCode" equalTo:self.navigationItem.title];
    
    // Search
    NSError *error;
    NSArray *dairyArray   = [query findObjects:&error];
    NSLog(@"arrays == %@", dairyArray);
    
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"接続エラー" message:@"インターネット接続をご確認ください。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
    

    //DataFormatter
    /*
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日HH時mm分"];
     */
    
    if([dairyArray count] > 0)
    {
        //保存した画像データを取得する
        for(PFObject *objectData in dairyArray) {
            PFFile *fileData = [objectData objectForKey:@"image"];
            PFObject *titleData = [objectData objectForKey:@"title"];
            NSString *contentData = [objectData objectForKey:@"content"];
            NSDate *createdDate = objectData.createdAt;
            //NSString *createdString = [dateFormatter stringFromDate:createdDate];
            __block UIImage *image;
            [fileData getDataInBackgroundWithBlock:^(NSData *imgData, NSError *error){
                image = [[UIImage alloc]initWithData:imgData];
                NSLog(@"createdDate == %@", createdDate);
                [imageArray insertObject:image atIndex:0];
                [titleArray insertObject:titleData atIndex:0];
                [detailTextArray insertObject:contentData atIndex:0];
                
                if (!error) {
                    [tableView reloadData];
                }
            }];
            
        }
    }else{
        NSLog(@"No Data");
    }
}



- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - UITextView Delegate

-(BOOL)textViewShouldBeginEditing:(UITextView*)textView
{
    [self.contentField resignFirstResponder];
    if ([self.contentField.text isEqualToString:@"内容"]) {
        self.contentField.text = @"";
    }
    return YES;
}



@end
