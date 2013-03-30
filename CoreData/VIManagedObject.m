//
//  VIManagedObject.m
//  CoreData
//

#import "VIManagedObject.h"
#import "VICoreDataManager.h"

@implementation NSManagedObject (VIManagedObjectAdditions)

- (void)safeSetValue:(id)value forKey:(NSString *)key
{
    if (value && ![[NSNull null] isEqual:value]) {
        [self setValue:value forKey:key];
    } else {
        [self setNilValueForKey:key];
    }
}

#pragma mark - Add Objects
+ (NSArray *)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    return [[VICoreDataManager sharedInstance] importArray:inputArray forClass:[self class] withContext:contextOrNil];
}

+ (NSManagedObject *)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    return [[VICoreDataManager sharedInstance] importDictionary:inputDict forClass:[self class] withContext:contextOrNil];
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
