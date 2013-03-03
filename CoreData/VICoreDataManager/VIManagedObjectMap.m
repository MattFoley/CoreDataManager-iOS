//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMap.h"
#import "VICoreDataManager.h"

@implementation VIManagedObjectMap

+ (instancetype)mapWithInput:(NSString *)inputKey output:(NSString *)outputKey
{
    return [self mapWithInput:inputKey output:outputKey dateFormatter:nil];
}

+ (instancetype)mapWithInput:(NSString *)inputKey
                      output:(NSString *)outputKey
               dateFormatter:(NSDateFormatter *)dateFormatter
{
    VIManagedObjectMap *map = [[self alloc] init];
    [map setInputKey:inputKey];
    [map setCoreDataKey:outputKey];
    [map setDateFormatter:dateFormatter];
    return map;
}

+ (NSArray *)mapsFromDictionary:(NSDictionary *)mapDict
{
    NSMutableArray *mapArray = [NSMutableArray array];

    [mapDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //key = input key, obj = core data key
        [mapArray addObject:[self mapWithInput:key output:obj]];
    }];

    return [mapArray copy];
}

+ (NSDateFormatter *)internetDateFormetter
{
    static NSDateFormatter *df;

    if (!df) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return df;
}

@end
