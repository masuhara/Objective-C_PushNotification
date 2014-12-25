//
//  ViewController.m
//  KoukanNote
//
//  Created by 井上ユカリ on 2014/06/07.
//  Copyright (c) 2014年 YukariInoue. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}



#pragma mark- NavigationBarの非表示

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // NavigationBar 非表示
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // NavigationBar 表示
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
