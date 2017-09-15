//
//  FQAppSettingDataBase.m
//  FQFMDB
//
//  Created by 冯倩 on 2017/7/27.
//  Copyright © 2017年 冯倩. All rights reserved.
//

#import "FQAppSettingDataBase.h"
#import "FQDataBase.h"

@implementation FQAppSettingDataBase

/** 初始化 */
+ (void)ready
{
    [[FQDataBase defaultDatabase] createOrUpdateTableNamed:@"app_setting"
                                              updateAction:^BOOL(FMDatabase *db, SInt32 version)
     {
         BOOL r = [FQDataBase inDatabase:db
                     creatTableIfNotExit:@"app_setting"
                             columnArray:
                   @[@"key",@"value"]];
         if (!r)
         {
             return NO;
         }
         return r;
     }];
}


#pragma mark - 增加,若增加为空则删除
/** 设置指定数据，key==nil则无操作 */
+ (void)setObject:(nullable id)obj forKey:(nullable NSString *)key
{
    if (!key)
    {
        return;
    }
    
    if (obj == nil)//若传来为nil,则删掉这个值
    {
        [[FQDataBase defaultDatabase] deleteFromTable:@"app_setting" whereEqualDic:@{@"key": key}];
    }
    else
    {
        [[FQDataBase defaultDatabase] insertOrUpdateTable:@"app_setting"
                                                   setDic:@{@"value": obj}
                                                 whereDic:@{@"key": key}];
    }
}

#pragma mark - 删除
+ (void)deleteKey:(nullable NSString *)key
{
    [self setObject:nil forKey:key];
}



#pragma mark - 读取数据
/** 读取指定数据，没有数据或key==nil或类型不符则返回nil */
+ (nullable NSData *)dataForKey:(nullable NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSData class]])
    {
        return obj;
    }
    return nil;
}
/** 读取指定数据，没有数据或key==nil或类型不符则返回nil */
+ (nullable NSString *)stringForKey:(nullable NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
    {
        return obj;
    }
    return nil;
}

/** 读取指定数据，没有数据或key==nil或类型不符则返回nil */
+ (nullable NSNumber *)numberForKey:(nullable NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSNumber class]])
    {
        return obj;
    }
    return nil;
}



/** 读取指定数据，没有数据或key==nil则返回nil */
+ (nullable id)objectForKey:(nullable NSString *)key
{
    if (!key)
    {
        return nil;
    }
    
    id data = [[FQDataBase defaultDatabase] selectFirstCol:@"value"
                                                 fromTable:@"app_setting"
                                             whereEqualDic:@{@"key": key}];
    return data;
}



@end
