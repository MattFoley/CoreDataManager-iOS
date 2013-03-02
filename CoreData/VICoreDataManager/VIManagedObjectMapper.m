//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMapper.h"
#import "VICoreDataManager.h"

@interface VIManagedObjectMapper()
@property NSMutableArray *mapsArray;
@end

@implementation VIManagedObjectMapper

+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey andMaps:(NSArray *)mapsArray;
{
    VIManagedObjectMapper *map = [[self alloc] init];
    [map setUniqueComparisonKey:comparisonKey];
    [map setMapsArray:[mapsArray copy]];
    [map setDeleteRule:VIManagedObjectMapperOverwrite];
    return map;
}

@end

@implementation VIManagedObjectMapper (setInformationFromDictionary)
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
