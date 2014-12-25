//
//  AppDelegate.m
//  KoukanNote
//
//  Created by 井上ユカリ on 2014/06/07.
//  Copyright (c) 2014年 YukariInoue. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#pragma mark - code for iOS8
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        // iOS 8 Notifications
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
#endif
    }else{
        // iOS < 8 Notifications
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|                                                UIRemoteNotificationTypeAlert|                                              UIRemoteNotificationTypeSound];
    }
    
    
    [Parse setApplicationId:@"zhd87RJZWu7EDMvHEqGVv2aj6zoqfWRaSB38mAgs" clientKey:@"LrVlyGiwPxxApB8AioNkuiTarjQs4zjobnEXH0pp"];

    
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (userInfo != nil) {
        application = [UIApplication sharedApplication];
        application.applicationIconBadgeNumber++;
    }
    
    application.applicationIconBadgeNumber = 0;
    
    
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Register Parse
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"didRegisterForRemoteNotification");
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (succeeded) {
            [PFPush storeDeviceToken:deviceToken];
        }else{
            NSLog(@"%@の理由でデバイストークンの保存に失敗", error);
        }
    }];
    
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    if (userInfo) {
        
        NSLog(@"userInfo == %@", userInfo);
        
        NSString *alertString = [[userInfo objectForKey:@"aps"] valueForKey:@"alert"];

        if (application.applicationState == UIApplicationStateActive)
        {
            //TODO:調整してね
            application = [UIApplication sharedApplication];
            application.applicationIconBadgeNumber++;
        }
        
        if (application.applicationState == UIApplicationStateInactive)
        {
            //TODO:調整してね
            application = [UIApplication sharedApplication];
            application.applicationIconBadgeNumber++;
        }
        
        
        
        // =========== Notification =========== //
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        if(localNotification == nil) {
            return;
        }
        
        
        localNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:1.5];
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        //localTimeZone → defaultTimeZone
        
        localNotification.alertAction = @"KOUKAN NOTE";
        localNotification.alertBody = alertString;
        
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        
        
        // ========= Foreground Notification ========
        //
        //「handlePush」を使うとフォアグラウンド時にアラートが表示される
        //[PFPush handlePush:userInfo];
        
    }
    
}





@end
