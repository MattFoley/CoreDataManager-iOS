//
//  VIManagedObject.h
//  CoreData
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (VIManagedObjectAdditions)

- (void)safeSetValue:(id)value forKey:(NSString *)key;

//If contextOrNil is nil the main context will be used.
+ (NSArray *)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;
+ (NSManagedObject *)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;


//These will adhere to the NSManagedObjectContext of the managedObject.
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;


//These allow for more flexibility.
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;

@end