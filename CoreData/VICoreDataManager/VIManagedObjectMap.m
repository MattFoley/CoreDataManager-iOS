//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMap.h"
#import "VICoreDataManager.h"

@interface VIManagedObjectMap() {
    NSString *_comparisonKey;
    NSDictionary *_mappingDictionary;
}
@end

@implementation VIManagedObjectMap

+ (instancetype)mapWithUniqueKey:(NSString *)comparisonKey mappingDictionary:(NSDictionary *)mappingDict
{
    VIManagedObjectMap *map = [[self alloc] init];
    [map setUniqueComparisonKey:comparisonKey];
    [map setMappingDictionary:mappingDict];
    [map setDeleteRule:VIManagedObjectMapOverwrite];
    return map;
}

@end

@implementation VIManagedObjectMap (setInformationFromDictionary)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    [inputDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id translatedKey = [self.mappingDictionary valueForKey:key];

        //todo - put checks for NSNumber and NSDate with dateformatter
        if (![obj isEqual:[NSNull null]]) {
            [object setValue:obj forKey:translatedKey];
        }

    }];
}

@end
