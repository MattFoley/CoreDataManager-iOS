//
//  VIManagedObjectMap.h
//  CoreData
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

//default is VIManagedObjectMapOverwrite
typedef NS_ENUM(NSUInteger, VIManagedObjectMapDeleteRule){
    VIManagedObjectMapDeleteAll,    //delete all existing objects of a class before importing
    VIManagedObjectMapOverwrite,    //overwrite local changes with the new dictionary
    VIManagedObjectMapDoNotUpdate,  //leave existing objects alone
};

@interface VIManagedObjectMap : NSObject
@property NSString *uniqueComparisonKey;
@property VIManagedObjectMapDeleteRule deleteRule;

//key = expected input key
//value = core data key
@property NSDictionary *mappingDictionary;

+ (instancetype)mapWithUniqueKey:(NSString *)comparisonKey mappingDictionary:(NSDictionary *)mappingDict;

@end