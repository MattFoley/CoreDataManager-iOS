//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMapper.h"
#import "VICoreDataManager.h"

@interface VIManagedObjectMapper()
@property NSArray *mapsArray;
- (id)checkDate:(id)inputObject withDateFormatter:(NSDateFormatter *)dateFormatter;
- (id)checkClass:(id)inputObject managedObject:(NSManagedObject *)managedObject key:(NSString *)key;
- (Class)expectedClassForObject:(NSManagedObject *)object andKey:(id)key;
@end

@implementation VIManagedObjectMapper

+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey andMaps:(NSArray *)mapsArray;
{
    VIManagedObjectMapper *mapper = [[self alloc] init];
    [mapper setUniqueComparisonKey:comparisonKey];
    [mapper setMapsArray:mapsArray];
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

- (id)checkNull:(id)inputObject
{
    if ([[NSNull null] isEqual:inputObject]) {
        return nil;
    }
    return inputObject;
}

- (id)checkDate:(id)inputObject withDateFormatter:(NSDateFormatter *)dateFormatter
{
    id date = [dateFormatter dateFromString:inputObject];
    if (date) {
        return date;
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
    NSDictionary *attributes = [[object entity] attributesByName];
    NSAttributeDescription *attributeDescription = [attributes valueForKey:key];
    return NSClassFromString([attributeDescription attributeValueClassName]);
}

@end

@implementation VIManagedObjectMapper (setInformationFromDictionary)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)managedObject
{
    [self.mapsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        VIManagedObjectMap *map = obj;
        id inputObject = [inputDict objectForKey:map.inputKey];
        inputObject = [self checkNull:inputObject];
        inputObject = [self checkClass:inputObject managedObject:managedObject key:map.coreDataKey];
        inputObject = [self checkDate:inputObject withDateFormatter:map.dateFormatter];
        [managedObject safeSetValue:inputObject forKey:map.coreDataKey];
    }];
}
@end

@implementation VIManagedObjectDefaultMapper
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)managedObject
{
    //this default mapper assumes that local keys and entities match foreign keys and entities
    [inputDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id inputObject = obj;
        inputObject = [self checkNull:inputObject];
        inputObject = [self checkClass:inputObject managedObject:managedObject key:key];
        inputObject = [self checkDate:inputObject withDateFormatter:[VIManagedObjectMap defaultDateFormatter]];
        [managedObject safeSetValue:inputObject forKey:key];
    }];
}
@end
