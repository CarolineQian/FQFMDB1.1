//
//  FQDataBase.m
//  FQFMDB
//
//  Created by 冯倩 on 2017/7/27.
//  Copyright © 2017年 冯倩. All rights reserved.
//

#import "FQDataBase.h"


@implementation FQDataBase
{
    FMDatabase      *_db;
    NSRecursiveLock *_recursiveLock;
}

static NSString *_DefaultDatabasePath = nil;

#pragma mark - 设置路径
+ (void)setDefaultDatabasePath:(NSString *)path
{
    if (_DefaultDatabasePath)
    {
        if (![_DefaultDatabasePath isEqualToString:path])
        {
            NSLog(@"已经设置过路径：%@，\n无法修改为：%@", _DefaultDatabasePath, path);
        }
    }
    else
    {
        _DefaultDatabasePath = [path copy];
    }
}

/** 全局默认的数据库（需要先设置路径） */
+ (instancetype)defaultDatabase
{
    static FQDataBase *defaultDatabase = nil;
    if (!defaultDatabase)
    {
        @synchronized (self)
        {
            if (!defaultDatabase)
            {
                //根据路径创建了FQDataBase
                defaultDatabase = [[self alloc] initWithPath:_DefaultDatabasePath];
                if (!defaultDatabase)
                {
                    if (_DefaultDatabasePath)
                    {
                        NSLog(@"数据库路径使用失败：%@", _DefaultDatabasePath);
                    }
                    else
                    {
                        NSLog(@"没有设置数据库路径");
                    }
                }
            }
        }
    }
    return defaultDatabase;
}

#pragma mark - 创建数据库
- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        _db = [[FMDatabase alloc] initWithPath:path];
        _recursiveLock = [[NSRecursiveLock alloc] init];
        BOOL success = [_db open];
        if (!success)
        {
            NSLog(@"数据库创建失败，路径：%@", path);
            self = nil;
        }
    }
    return self;
}


#pragma mark - 创建表
- (void)createOrUpdateTableNamed:(NSString *)tableName updateAction:(BOOL (^)(FMDatabase *db, SInt32 lastVersion))block
{
    if (block(_db, 1))
    {
        NSLog(@"FQ设置表成功");
    }
    else
    {
        NSLog(@"FQ设置表失败");
    }
}

/** 表不存在则创建（存在时不检查列是否相同） */
+ (BOOL)inDatabase:(FMDatabase *)db creatTableIfNotExit:(NSString *)table columnArray:(NSArray *)colArray
{
    NSMutableString *columnStr = [NSMutableString string];
    BOOL first = YES;
    for (NSString *col in colArray)
    {
        if (first)
        {
            first = NO;
        } else
        {
            [columnStr appendString:@","];
        }
        [columnStr appendString:col];
    }
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS `%@`(%@)", table, columnStr];
    BOOL r = [db executeUpdate:sql];
    if (!r)
    {
        NSLog(@"db create table fail:[errCode:]%d [Msg:]%@", [db lastErrorCode], [db lastErrorMessage]);
    }
    return r;
}

#pragma mark - 本类中多次会使用加锁
- (void)inDatabase:(void (^)(FMDatabase *db))block
{
    [_recursiveLock lock];
    block(_db);
    [_recursiveLock unlock];
}

#pragma mark -  增加
/** 有则修改dataDic，无则插入whereDic和dataDic的合集 */
- (BOOL)insertOrUpdateTable:(NSString *)table setDic:(NSDictionary *)dataDic whereDic:(NSDictionary *)whereDic
{
    __block BOOL r;
    [self inDatabase:^(FMDatabase *db)
     {
         //有
        if ([FQDataBase inDatabase:db hasSelectCol:[dataDic allKeys] fromTable:table whereEqualDic:whereDic])
        {
            r = [FQDataBase inDatabase:db updateTable:table setDic:dataDic whereDic:whereDic];
            if (!r)
            {
                NSLog(@"插入或更新，更新时失败keys:%@，where:%@",[dataDic allKeys],whereDic);
            }
        }
         //无
        else
        {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:whereDic];
            [dic addEntriesFromDictionary:dataDic];
            r = [FQDataBase inDatabase:db insertIntoTable:table setDic:dic];
            if (!r)
            {
                NSLog(@"插入或更新，插入时失败keys:%@，where:%@",[dataDic allKeys],whereDic);
            }
        }
    }];
    return r;
}


//检查是否有
+ (BOOL)inDatabase:(FMDatabase *)db hasSelectCol:(NSArray *)colArr fromTable:(NSString *)table whereEqualDic:(NSDictionary *)dic
{
    NSMutableString * colStr = [NSMutableString string];
    
    for (int i=0; i<colArr.count; i++)
    {
        if (i != 0)
        {
            [colStr appendString:@","];
        }
        [colStr appendString:[colArr objectAtIndex:i]];
    }
    
    NSString *sql;
    if (dic.count>0)
    {
        NSMutableString *whereStr = [NSMutableString stringWithString:@"WHERE "];
        BOOL first = YES;
        for (NSString *key in dic)
        {
            if (first)
            {
                first = NO;
            }
            else
            {
                [whereStr appendString:@" AND "];
            }
            [whereStr appendFormat:@"%@=:%@",key,key];
        }
        sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@", colStr,table, whereStr];
    }
    else
    {
        sql = [NSString stringWithFormat:@"SELECT %@ FROM %@", colStr,table];
    }
    
    
    FMResultSet *result = [db executeQuery:sql withParameterDictionary:dic];
    if (!result)
    {
        NSLog(@"db select fail:[errCode:]%d [Msg:]%@", [db lastErrorCode], [db lastErrorMessage]);
    }
    BOOL r = [result next];
    [result close];
    return r;
}


//有这个数据,改值
+ (BOOL)inDatabase:(FMDatabase *)db updateTable:(NSString *)table setDic:(NSDictionary *)dataDic whereDic:(NSDictionary *)whereDic
{
    BOOL r;
    NSMutableString *setStr = [NSMutableString string];
    NSMutableString *whereStr = [NSMutableString string];
    NSMutableArray *argumentArray = [NSMutableArray array];
    
    BOOL first = YES;
    
    for (NSString *key in dataDic)
    {
        if (first)
        {
            first = NO;
        }
        else
        {
            [setStr appendString:@","];
        }
        [setStr appendFormat:@"%@=?",key];
        [argumentArray addObject:[dataDic valueForKey:key]];
    }
    first = YES;
    for (NSString *key in whereDic)
    {
        if (first)
        {
            first = NO;
            [whereStr appendString:@" WHERE "];
        }
        else
        {
            [whereStr appendString:@" AND "];
        }
        [whereStr appendFormat:@"%@=?",key];
        [argumentArray addObject:[whereDic valueForKey:key]];
    }
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ %@", table , setStr, whereStr];
    r = [db executeUpdate:sql withArgumentsInArray:argumentArray];
    if (!r)
    {
        NSLog(@"db update fail:[errCode:]%d [Msg:]%@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    return r;
}


//无此数据,插入
+ (BOOL)inDatabase:(FMDatabase *)db insertIntoTable:(NSString *)table setDic:(NSDictionary *)dic
{
    BOOL r;
    NSMutableString *keyStr = [NSMutableString string];
    NSMutableString *valueStr = [NSMutableString string];
    
    BOOL first = YES;
    for (NSString *key in dic)
    {
        if (first)
        {
            first = NO;
        }
        else
        {
            [keyStr appendString:@","];
            [valueStr appendString:@","];
        }
        [keyStr appendString:key];
        [valueStr appendFormat:@":%@",key];
    }
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@)VALUES(%@)", table,keyStr,valueStr];
    r = [db executeUpdate:sql withParameterDictionary:dic];
    if (!r)
    {
        NSLog(@"db insert fail:[errCode:]%d [Msg:]%@", [db lastErrorCode], [db lastErrorMessage]);
    }
    return r;
}




#pragma mark - 删除
- (BOOL)deleteFromTable:(NSString *)table whereEqualDic:(NSDictionary *)whereDic
{
    __block BOOL r;
    [self inDatabase:^(FMDatabase *db)
     {
         r = [FQDataBase inDatabase:db deleteFromTable:table whereEqualDic:whereDic];
     }];
    return r;
}

+ (BOOL)inDatabase:(FMDatabase *)db deleteFromTable:(NSString *)table whereEqualDic:(NSDictionary *)dic
{
    NSString *sql;
    if (dic.count>0)
    {
        NSMutableString *whereStr = [NSMutableString stringWithString:@"WHERE "];
        BOOL first = YES;
        for (NSString *key in dic)
        {
            if (first)
            {
                first = NO;
            }
            else
            {
                [whereStr appendString:@" AND "];
            }
            [whereStr appendFormat:@"%@=:%@",key,key];
        }
        sql = [NSString stringWithFormat:@"DELETE FROM %@ %@", table, whereStr];
    }
    else
    {
        sql = [NSString stringWithFormat:@"DELETE FROM %@", table];
    }
    BOOL r = [db executeUpdate:sql withParameterDictionary:dic];
    if (!r)
    {
        NSLog(@"db delete fail:[errCode:]%d [Msg:]%@", [db lastErrorCode], [db lastErrorMessage]);
    }
    return r;
}

#pragma mark - 查找

- (id)selectFirstCol:(NSString *)colName fromTable:(NSString *)table whereEqualDic:(NSDictionary *)dic
{
    __block id resultData = nil;
    [self inDatabase:^(FMDatabase *db)
    {
        resultData = [FQDataBase inDatabase:db selectFirstCol:colName fromTable:table whereEqualDic:dic];
    }];
    return resultData;
}

+ (id)inDatabase:(FMDatabase *)db selectFirstCol:(NSString *)colName fromTable:(NSString *)table whereEqualDic:(NSDictionary *)dic
{
    NSString *sql;
    if (dic.count > 0)
    {
        NSMutableString *whereStr = [NSMutableString stringWithString:@"WHERE "];
        BOOL first = YES;
        for (NSString *key in dic)
        {
            if (first)
            {
                first = NO;
            } else {
                [whereStr appendString:@" AND "];
            }
            [whereStr appendFormat:@"%@=:%@",key,key];
        }
        sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@", colName,table, whereStr];
    } else
    {
        sql = [NSString stringWithFormat:@"SELECT %@ FROM %@", colName,table];
    }
    FMResultSet *result = [db executeQuery:sql withParameterDictionary:dic];
    if (!result)
    {
        NSLog(@"db select fail:[errCode:]%d [Msg:]%@", [db lastErrorCode], [db lastErrorMessage]);
        return nil;
    }
    
    id data = nil;
    if ([result next])
    {
        data = [result objectForColumnIndex:0];
        if ([data isKindOfClass:[NSNull class]])
        {
            data = nil;
        }
    }
    [result close];
    return data;
}



@end
