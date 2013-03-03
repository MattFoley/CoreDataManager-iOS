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
    VIManagedObjectMapper *mapper = [[self alloc] init];
    [mapper setUniqueComparisonKey:comparisonKey];
    [mapper setMapsArray:[mapsArray copy]];
    [mapper setDeleteRule:VIManagedObjectMapperOverwrite];
    return mapper;
}

@end

@implementation VIManagedObjectMapper (setInformationFromDictionary)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)managedObject
{
    [self.mapsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        VIManagedObjectMap *map = obj;
        id inputObject = [inputDict objectForKey:map.inputKey];

        //apply date formatter, if needed
        if (map.dateFormatter && [inputObject isKindOfClass:[NSString class]]) {
            inputObject = [map.dateFormatter dateFromString:inputObject];
        }

        inputObject = [self checkNull:inputObject];
        
        //check for expected class
        Class expectedClass = [self expectedClassForObject:managedObject andKey:map.coreDataKey];
        if (![inputObject isKindOfClass:expectedClass]) {
            NSLog(@"wrong kind of class for %@\nexpected: %@\nreceived: %@",managedObject,NSStringFromClass(expectedClass),NSStringFromClass([inputObject class]));
            inputObject = nil;
        }

        if (inputObject) {
            [managedObject setValue:inputObject forKey:map.coreDataKey];
        } else {
            [managedObject setNilValueForKey:map.coreDataKey];
        }
    }];
}

#pragma mark - Convenience Methods
- (id)checkNull:(id)inputObject
{
    if ([inputObject isEqual:[NSNull null]]) {
        return nil;
    }
    return inputObject;
}

- (Class)expectedClassForObject:(NSManagedObject *)object andKey:(id)key
{
    NSEntityDescription *description = object.entity;
    NSDictionary *attributes = [description attributesByName];
    NSAttributeDescription *attributeDescription = [attributes valueForKey:key];
    return [self classFromAttributeType:attributeDescription.attributeType];
}

- (Class)classFromAttributeType:(NSAttributeType)attributeType
{
    if (attributeType == NSDateAttributeType) {
        return [NSDate class];
    }
    if (attributeType == NSStringAttributeType) {
        return [NSString class];
    }
    if (attributeType == NSBinaryDataAttributeType) {
        return [NSData class];
    }
    if (attributeType != 0 && attributeType < 1000) {
        return [NSNumber class];
    }

    NSLog(@"there is an odd attribute type here");
    NSLog(@"attribute is %d",attributeType);
    return nil;
}


@end
