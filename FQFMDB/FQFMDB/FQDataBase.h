//
//  FQDataBase.h
//  FQFMDB
//
//  Created by 冯倩 on 2017/7/27.
//  Copyright © 2017年 冯倩. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>

@interface FQDataBase : NSObject

/** 设置全局默认数据库的路径 */
+ (void)setDefaultDatabasePath:(NSString *)path;

/** 全局默认的数据库（需要先设置路径） */
+ (instancetype)defaultDatabase;

/** 创建或更新数据表 */
#pragma mark - 创建表
- (void)createOrUpdateTableNamed:(NSString *)tableName updateAction:(BOOL (^)(FMDatabase *db, SInt32 lastVersion))block;

+ (BOOL)inDatabase:(FMDatabase *)db creatTableIfNotExit:(NSString *)table columnArray:(NSArray *)colArray;


#pragma mark - 增加

- (BOOL)insertOrUpdateTable:(NSString *)table setDic:(NSDictionary *)dataDic whereDic:(NSDictionary *)whereDic;

#pragma mark - 删除

- (BOOL)deleteFromTable:(NSString *)table whereEqualDic:(NSDictionary *)whereDic;


#pragma mark - 查找
- (id)selectFirstCol:(NSString *)colName fromTable:(NSString *)table whereEqualDic:(NSDictionary *)dic;
@end
