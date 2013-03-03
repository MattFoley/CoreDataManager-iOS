//
//  VIManagedObject.h
//  CoreData
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (VIManagedObjectAdditions)

- (void)safeSetValue:(id)value forKey:(NSString *)key;

//If contextOrNil is nil the main context will be used.
+ (void)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;
+ (void)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;

@end