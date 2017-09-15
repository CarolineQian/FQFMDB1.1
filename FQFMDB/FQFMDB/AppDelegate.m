//
//  AppDelegate.m
//  FQFMDB
//
//  Created by 冯倩 on 2017/7/25.
//  Copyright © 2017年 冯倩. All rights reserved.
//

#import "AppDelegate.h"
#import "FQDataBase.h"
#import "FQAppSettingDataBase.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    NSString *home    = NSHomeDirectory();
    NSString *oldPath = [home stringByAppendingPathComponent:@"Documents/FQdata.db"];
    NSLog(@"我的数据库地址是什么%@",oldPath);
    //给FQDataBase中的_DefaultDatabasePath赋了路径
    [FQDataBase setDefaultDatabasePath:oldPath];
    //配置表
    [FQAppSettingDataBase ready];
    
    
    //增加
    [FQAppSettingDataBase setObject:nil forKey:@"app_version"];
    [FQAppSettingDataBase setObject:@(100) forKey:@"interview_comment_guide"];
    [FQAppSettingDataBase setObject:@"3.2.1" forKey:@"app_version"];
    NSData* xmlData = [@"testdata" dataUsingEncoding:NSUTF8StringEncoding];
    [FQAppSettingDataBase setObject:xmlData forKey:@"app_data"];
    
    //查找读取
    NSString *str = [FQAppSettingDataBase stringForKey:@"app_version"];
    NSLog(@"str是什么%@",str);
    
    NSNumber *number = [FQAppSettingDataBase numberForKey:@"interview_comment_guide"];
    NSLog(@"number是什么%@",number);
    

    NSData *data = [FQAppSettingDataBase dataForKey:@"app_data"];
    NSString *strData = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
    NSLog(@"data是什么%@",strData);
    
    
    NSString *objectString = [FQAppSettingDataBase objectForKey:@"app_version"];
    NSLog(@"objectString是什么%@",objectString);


    return YES;
}





@end
