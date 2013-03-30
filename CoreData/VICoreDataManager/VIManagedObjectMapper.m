//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMapper.h"
#import "VICoreDataManager.h"

@interface VIManagedObjectMapper()
@property NSArray *mapsArray;
- (id)checkNull:(id)inputObject;
- (id)checkDate:(id)inputObject withDateFormatter:(NSDateFormatter *)dateFormatter;
- (BOOL)checkClass:(id)inputObject managedObject:(NSManagedObject *)object key:(NSString *)key;
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
    if (!date) {
        return inputObject;
    }
    return date;
}

- (BOOL)checkClass:(id)inputObject managedObject:(NSManagedObject *)object key:(NSString *)key
{
    Class expectedClass = [self expectedClassForObject:object andKey:key];
    if (![inputObject isKindOfClass:expectedClass]) {
        NSLog(@"Wrong kind of class for %@\nExpected: %@\nReceived: %@",object,NSStringFromClass(expectedClass),NSStringFromClass([inputObject class]));
        return NO;
    }
    return YES;
}

- (Class)expectedClassForObject:(NSManagedObject *)object andKey:(id)key
{
    NSDictionary *attributes = [[object entity] attributesByName];
    NSAttributeDescription *attributeDescription = [attributes valueForKey:key];
    return NSClassFromString([attributeDescription attributeValueClassName]);
}

@end

@implementation VIManagedObjectMapper (setInformationFromDictionary)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    [self.mapsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        VIManagedObjectMap *map = obj;
        id inputObject = [inputDict objectForKey:map.inputKey];
        if ([self checkClass:inputObject managedObject:object key:map.coreDataKey]) {
            inputObject = [self checkNull:inputObject];
            inputObject = [self checkDate:inputObject withDateFormatter:map.dateFormatter];
            [object safeSetValue:inputObject forKey:map.coreDataKey];
        }
    }];
}
@end

@implementation VIManagedObjectDefaultMapper
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    //this default mapper assumes that local keys and entities match foreign keys and entities
    [inputDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id inputObject = obj;
        if ([self checkClass:inputObject managedObject:object key:key]) {
            inputObject = [self checkNull:inputObject];
            inputObject = [self checkDate:inputObject withDateFormatter:[VIManagedObjectMap defaultDateFormatter]];
            [object safeSetValue:inputObject forKey:key];
        }
    }];
}
@end
