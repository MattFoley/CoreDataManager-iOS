//
//  VICoreDataManager.h
//  CoreData
//

#ifndef __IPHONE_5_0
#warning "VICoreDataManager uses features only available in iOS SDK 5.0 and later."
#endif

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VIManagedObjectMapper.h"
#import "VIManagedObject.h"
#import "VIFetchResultsDataSource.h"

FOUNDATION_EXTERN NSString *const VICOREDATA_NOTIFICATION_ICLOUD_UPDATED;

@interface VICoreDataManager : NSObject

+ (VICoreDataManager *)getInstance;

- (NSManagedObjectContext *)managedObjectContext;

//be sure to use one of these setup methods before interacting with Core Data
- (void)setResource:(NSString *)resource database:(NSString *)database;
- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId;

//Create and configure new NSManagedObject subclasses
//If contextOrNil is nil the main context will be used.
- (NSManagedObject *)addObjectForClass:(Class)managedObjectClass forContext:(NSManagedObjectContext *)contextOrNil;
- (BOOL)setObjectMapper:(VIManagedObjectMapper *)objMap forClass:(Class)objectClass;
- (void)importArray:(NSArray *)inputArray forClass:(Class)objectClass withContext:(NSManagedObjectContext*)contextOrNil;
- (void)importDictionary:(NSDictionary *)inputDict forClass:(Class)objectClass withContext:(NSManagedObjectContext *)contextOrNil;
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object;

//Fetch and delete NSManagedObject subclasses
//NOT threadsafe! Be sure to use a temp context if you are NOT on the main thread.
- (NSArray *)arrayForClass:(Class)managedObjectClass;
- (NSArray *)arrayForClass:(Class)managedObjectClass forContext:(NSManagedObjectContext *)contextOrNil;
- (NSArray *)arrayForClass:(Class)managedObjectClass withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil;

- (void)deleteObject:(NSManagedObject *)object;
- (BOOL)deleteAllObjectsOfClass:(Class)managedObjectClass context:(NSManagedObjectContext *)contextOrNil;

//This saves the main context asynchronously on the main thread
- (void)saveMainContext;

//wrap your background transactions in these methods
- (NSManagedObjectContext *)startTransaction;
- (void)endTransactionForContext:(NSManagedObjectContext *)context;

//this deletes the persistent stores and resets the main context and model to nil
- (void)resetCoreData;

@end