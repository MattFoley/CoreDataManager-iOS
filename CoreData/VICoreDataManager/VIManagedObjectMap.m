//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMap.h"

@implementation VIManagedObjectMap

+ (instancetype)mapWithInput:(NSString *)inputKey output:(NSString *)outputKey
{
    return [self mapWithInput:inputKey output:outputKey expectedClass:[NSString class]];
}

+ (instancetype)mapWithInput:(NSString *)inputKey
                      output:(NSString *)outputKey
               expectedClass:(Class)expectedClass
{
    return [self mapWithInput:inputKey output:outputKey expectedClass:[NSString class] dateFormatter:nil];
}

+ (instancetype)mapWithInput:(NSString *)inputKey
                      output:(NSString *)outputKey
               expectedClass:(Class)expectedClass
               dateFormatter:(NSDateFormatter *)dateFormatter
{
    VIManagedObjectMap *map = [[self alloc] init];
    [map setInputKey:inputKey];
    
    
}

//default date handling
+ (NSDate *)dateFromInternetDate:(NSString *)dateString
{
    static NSDateFormatter *df;

    if (!df) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return df;
}

- (void)dateFormatter
{
    if (_dateFormatter) {
        return _dateFormatter;
    }

    return [[self class] dateFromInternetDate];
}

@end
