//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMapper.h"
#import "VICoreDataManager.h"
#import "VIEntityMetadataCache.h"

@interface VIManagedObjectMapper()
@property NSMutableArray *mapsArray;
@end

@implementation VIManagedObjectMapper

+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey andMaps:(NSArray *)mapsArray;
{
    VIManagedObjectMapper *mapper = [[self alloc] init];
    [mapper setUniqueComparisonKey:comparisonKey];
    [mapper setMapsArray:[mapsArray copy]];
    return mapper;
}

+ (instancetype)defaultMapper
{
    return [[VIManagedObjectDefaultMapper alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        _deleteAllBeforeImport = YES;
        _overwriteObjectsWithServerChanges = YES;
    }
    return self;
}

@end

@implementation VIManagedObjectMapper (setInformationFromDictionary)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)managedObject
{
    [self.mapsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        VIManagedObjectMap *map = obj;
        id inputObject = [inputDict objectForKey:map.inputKey];

        inputObject = [self checkNull:inputObject];
        inputObject = [self checkDate:inputObject withDateFormatter:map.dateFormatter];
        inputObject = [self checkClass:inputObject managedObject:managedObject key:map.coreDataKey];

        [managedObject safeSetValue:inputObject forKey:map.coreDataKey];
    }];
}

- (id)checkDate:(id)inputObject withDateFormatter:(NSDateFormatter *)dateFormatter
{
    id date = [dateFormatter dateFromString:inputObject];
    if (date) {
        return date;
    }

    return inputObject;
}

- (id)checkNull:(id)inputObject
{
    if ([inputObject isEqual:[NSNull null]]) {
        return nil;
    }
    return inputObject;
}

- (id)checkClass:(id)inputObject managedObject:(NSManagedObject *)managedObject key:(NSString *)key
{
    Class expectedClass = [self expectedClassForObject:managedObject andKey:key];
    if (![inputObject isKindOfClass:expectedClass]) {
        NSLog(@"wrong kind of class for %@\nexpected: %@\nreceived: %@",managedObject,NSStringFromClass(expectedClass),NSStringFromClass([inputObject class]));
        inputObject = nil;
    }
    return inputObject;
}

- (Class)expectedClassForObject:(NSManagedObject *)object andKey:(id)key
{
    NSEntityDescription *description = object.entity;
    NSDictionary *attributes = [description attributesByName];
    NSAttributeDescription *attributeDescription = [attributes valueForKey:key];
    return NSClassFromString([attributeDescription attributeValueClassName]);
}

@end

@implementation VIManagedObjectDefaultMapper

- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)managedObject
{
    //this default mapper assumes that local keys and entities match foreign keys and entities
    [inputDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id inputObject = obj;
        inputObject = [self checkNull:inputObject];
        inputObject = [self checkDate:inputObject withDateFormatter:[VIManagedObjectMap defaultDateFormatter]];
        inputObject = [self checkClass:inputObject managedObject:managedObject key:key];

        [managedObject safeSetValue:inputObject forKey:key];
    }];
}

@end
