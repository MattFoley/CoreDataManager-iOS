//
//  VIManagedObject.m
//  CoreData
//

#import "VIManagedObject.h"
#import "VICoreDataManager.h"

@implementation NSManagedObject (VIManagedObjectAdditions)

- (void)safeSetValue:(id)value forKey:(NSString *)key
{
    if (value && ![value isEqual:[NSNull null]]) {
        [self setValue:value forKey:key];
    } else {
        [self setNilValueForKey:key];
    }
}

#pragma mark - Class Methods
+ (void)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    [[VICoreDataManager getInstance] importArray:inputArray forClass:[self class] withContext:contextOrNil];
}

+ (void)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    [[VICoreDataManager getInstance] importDictionary:inputDict forClass:[self class] withContext:contextOrNil];
}

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    return [self fetchForPredicate:predicate forManagedObjectContext:contextOrNil] != nil;
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    NSArray *results = [[VICoreDataManager getInstance] arrayForClass:[self class]
                                                        withPredicate:predicate
                                                           forContext:contextOrNil];
    return results;
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    NSArray *results = [self fetchAllForPredicate:predicate forManagedObjectContext:contextOrNil];

    if ([results count] > 0) {
        return [results lastObject];
    }

    return nil;
}

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    return [self fetchForPredicate:predicate forManagedObject:managedObject] != nil;
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    NSArray *results = [[VICoreDataManager getInstance] arrayForClass:[self class]
                                                        withPredicate:predicate
                                                           forContext:[managedObject managedObjectContext]];

    return results;
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    NSArray *results = [self fetchAllForPredicate:predicate forManagedObject:managedObject];

    if ([results count] > 0) {
        return [results lastObject];
    }

    return nil;
}

@end
