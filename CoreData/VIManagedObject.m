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

#pragma mark - Add Objects
+ (void)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    [[VICoreDataManager sharedInstance] importArray:inputArray forClass:[self class] withContext:contextOrNil];
}

+ (void)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    [[VICoreDataManager sharedInstance] importDictionary:inputDict forClass:[self class] withContext:contextOrNil];
}

#pragma mark - Fetch with Object's Context
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    return [self existsForPredicate:predicate forManagedObjectContext:[managedObject managedObjectContext]];
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    return [self fetchAllForPredicate:predicate forManagedObjectContext:[managedObject managedObjectContext]];
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    return [self fetchForPredicate:predicate forManagedObjectContext:[managedObject managedObjectContext]];
}

#pragma mark - Fetch with Context
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    return [self fetchAllForPredicate:predicate forManagedObjectContext:contextOrNil] != nil;
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    NSArray *results = [[VICoreDataManager sharedInstance] arrayForClass:[self class]
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

@end
