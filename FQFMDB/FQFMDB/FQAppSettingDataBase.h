//
//  FQAppSettingDataBase.h
//  FQFMDB
//
//  Created by 冯倩 on 2017/7/27.
//  Copyright © 2017年 冯倩. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FQAppSettingDataBase : NSObject

/** 初始化 */
+ (void)ready;


#pragma mark - 添加数据
/** 设置指定数据，key==nil则无操作 */
+ (void)setObject:(nullable id)obj forKey:(nullable NSString *)key;

#pragma mark - 删除
/** 删除指定数据，效果同[self setData:nil forKey:key] */
+ (void)deleteKey:(nullable NSString *)key;

#pragma mark - 读取数据
/** 读取指定数据，没有数据或key==nil则返回nil */
+ (nullable id)objectForKey:(nullable NSString *)key;
/** 读取指定数据，没有数据或key==nil或类型不符则返回nil */
+ (nullable NSData *)dataForKey:(nullable NSString *)key;
/** 读取指定数据，没有数据或key==nil或类型不符则返回nil */
+ (nullable NSString *)stringForKey:(nullable NSString *)key;
/** 读取指定数据，没有数据或key==nil或类型不符则返回nil */
+ (nullable NSNumber *)numberForKey:(nullable NSString *)key;


@end
