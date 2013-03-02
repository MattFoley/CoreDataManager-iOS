//
//  VIManagedObjectMap.h
//  CoreData
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VIManagedObjectMap.h"

//default is VIManagedObjectMapOverwrite
typedef NS_ENUM(NSUInteger, VIManagedObjectMapperDeleteRule){
    VIManagedObjectMapperDeleteAll,    //delete all existing objects of a class before importing
    VIManagedObjectMapperOverwrite,    //overwrite local changes with the new dictionary
    VIManagedObjectMapperDoNotUpdate,  //leave existing objects alone
};

@interface VIManagedObjectMapper : NSObject
@property NSString *uniqueComparisonKey;
@property VIManagedObjectMapperDeleteRule deleteRule;

+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey andMaps:(NSArray *)mapsArray;

@end