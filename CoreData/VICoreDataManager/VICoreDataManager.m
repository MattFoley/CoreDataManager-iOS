//
//  VICoreDataManager.m
//  CoreData
//

#import "VICoreDataManager.h"

NSString *const VICOREDATA_NOTIFICATION_ICLOUD_UPDATED = @"CDICloudUpdated";

NSString *const iCloudDataDirectoryName = @"Data.nosync";
NSString *const iCloudLogsDirectoryName = @"Logs";

@interface VICoreDataManager () {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property NSString *resource;
@property NSString *databaseFilename;
@property NSString *iCloudAppId;
@property NSString *bundleIdentifier;
@property NSMutableDictionary *mapperCollection;

- (NSBundle *)bundle;

//Getters
- (NSManagedObjectContext *)tempManagedObjectContext;
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

//Initializers
- (void)initManagedObjectModel;
- (void)initPersistentStoreCoordinator;
- (void)initManagedObjectContext;

//Thread Safety with Main MOC
- (NSManagedObjectContext *)threadSafeContext:(NSManagedObjectContext *)context;

//Context Saving and Merging
- (void)saveContext:(NSManagedObjectContext *)managedObjectContext;
- (void)saveTempContext:(NSManagedObjectContext *)tempContext;
- (void)tempContextSaved:(NSNotification *)notification;

//iCloud Integration - DO NOT USE
- (void)setupiCloudForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc;
- (void)mergeChangesFromiCloud:(NSNotification *)notification;

//Convenience Methods
- (VIManagedObjectMapper *)mapperForClass:(Class)objectClass;
- (NSURL *)applicationDocumentsDirectory;
- (void)debugPersistentStore;

@end

//private interface to VIManagedObjectMap
@interface VIManagedObjectMapper (setInformationFromDictionary)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)managedObject;
@end

static VICoreDataManager *_sharedObject = nil;

@implementation VICoreDataManager

+ (void)initialize
{
    //make sure the shared instance is ready
    [self getInstance];
}

+ (VICoreDataManager *)getInstance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (id)init
{
    self = [super init];
    if (self) {
        _mapperCollection = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setResource:(NSString *)resource database:(NSString *)database
{
    [self setResource:resource database:database iCloudAppId:nil];
}

- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId
{
    [self setResource:resource database:database iCloudAppId:iCloudAppId forBundleIdentifier:nil];
}

- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId forBundleIdentifier:(NSString *)bundleIdentifier
{
    //this method is publicized in unit tests
    self.resource = resource;
    self.databaseFilename = database;
    self.iCloudAppId = iCloudAppId;
    self.bundleIdentifier = bundleIdentifier;
}

- (NSBundle *)bundle
{
    // try your manually set bundle
    NSBundle *bundle = [NSBundle bundleWithIdentifier:self.bundleIdentifier];

    //default to main bundle
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }

    NSAssert(bundle, @"Missing bundle. Check the Bundle identifier on the plist of this target vs the identifiers array in this class.");

    return bundle;
}

#pragma mark - Getters
- (NSManagedObjectContext *)tempManagedObjectContext
{
    NSManagedObjectContext *tempManagedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if (coordinator) {
        tempManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        [tempManagedObjectContext setPersistentStoreCoordinator:coordinator];
    } else {
        NSLog(@"Coordinator is nil & context is %@", [tempManagedObjectContext description]);
    }

    return tempManagedObjectContext;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        [self initManagedObjectContext];
    }

    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {
        [self initManagedObjectModel];
    }

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator) {
        [self initPersistentStoreCoordinator];
    }

    return _persistentStoreCoordinator;
}


#pragma mark - Initializers
- (void)initManagedObjectModel
{
    NSURL *modelURL = [[self bundle] URLForResource:_resource withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (void)initPersistentStoreCoordinator
{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:self.databaseFilename];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if ([self.iCloudAppId length]) {
        [self setupiCloudForPersistantStoreCoordinator:_persistentStoreCoordinator];
    } else if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                          configuration:nil
                                                                    URL:storeURL
                                                                options:options
                                                                  error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void)initManagedObjectContext
{
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];

        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        id mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType];
        [_managedObjectContext setMergePolicy:mergePolicy];


        if ([_iCloudAppId length]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(mergeChangesFromiCloud:)
                                                         name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                       object:coordinator];
        }
    }
}

#pragma mark - Create and configure
- (NSManagedObject *)addObjectForClass:(Class)managedObjectClass forContext:(NSManagedObjectContext *)contextOrNil
{
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(managedObjectClass) inManagedObjectContext:contextOrNil];
}

- (BOOL)setObjectMapper:(VIManagedObjectMapper *)objMapper forClass:(Class)objectClass
{
    if (objMapper && objectClass) {
        [self.mapperCollection setObject:objMapper forKey:NSStringFromClass(objectClass)];
        return YES;
    }

    return NO;
}

- (void)importArray:(NSArray *)inputArray forClass:(Class)objectClass withContext:(NSManagedObjectContext*)contextOrNil
{
    VIManagedObjectMapper *mapper = [self mapperForClass:objectClass];
    if (mapper.deleteAllBeforeImport) {
        [self deleteAllObjectsOfClass:objectClass context:contextOrNil];
    }

    [inputArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [self importDictionary:obj forClass:objectClass withContext:contextOrNil];
        } else {
            NSLog(@"ERROR\n %s \nexpecting an NSArray full of NSDictionaries", __PRETTY_FUNCTION__);
        }
    }];
}

- (void)importDictionary:(NSDictionary *)inputDict forClass:(Class)objectClass withContext:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self threadSafeContext:contextOrNil];
    
    VIManagedObjectMapper *mapper = [self mapperForClass:objectClass];
    NSString *uniqueKey = [mapper uniqueComparisonKey];

    NSArray *existingObjectArray;
    if (uniqueKey) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ == %@",uniqueKey,[inputDict objectForKey:uniqueKey]];

        existingObjectArray = [self arrayForClass:objectClass withPredicate:predicate forContext:contextOrNil];
        NSAssert([existingObjectArray count] < 2, @"UNIQUE IDENTIFIER IS NOT UNIQUE. MORE THAN ONE MATCHING OBJECT FOUND");
    }

    if ([existingObjectArray count] && mapper.overwriteObjectsWithServerChanges) {
        NSManagedObject *existingObject = existingObjectArray[0];
        [self setInformationFromDictionary:inputDict forManagedObject:existingObject];
    } else {
        NSManagedObject *aNewObject = [self addObjectForClass:objectClass forContext:contextOrNil];
        [self setInformationFromDictionary:inputDict forManagedObject:aNewObject];
    }
}

- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    VIManagedObjectMapper *mapper = [self mapperForClass:[object class]];
    [mapper setInformationFromDictionary:inputDict forManagedObject:object];
}



#pragma mark -Fetch and delete
- (NSArray *)arrayForClass:(Class)managedObjectClass
{
    return [self arrayForClass:managedObjectClass forContext:nil];
}

- (NSArray *)arrayForClass:(Class)managedObjectClass forContext:(NSManagedObjectContext *)contextOrNil
{
    return [self arrayForClass:managedObjectClass withPredicate:nil forContext:contextOrNil];
}

- (NSArray *)arrayForClass:(Class)managedObjectClass withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self threadSafeContext:contextOrNil];

    NSString *entityName = NSStringFromClass(managedObjectClass);

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSArray *results = [contextOrNil executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Fetch Request Error\n%@",[error localizedDescription]);
    }

    return results;
}

- (void)deleteObject:(NSManagedObject *)object
{
    [[object managedObjectContext] deleteObject:object];
}

- (BOOL)deleteAllObjectsOfClass:(Class)managedObjectClass context:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self threadSafeContext:contextOrNil];

    NSString *entityName = NSStringFromClass(managedObjectClass);

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setIncludesPropertyValues:NO];

    NSError *error;
    NSArray *results = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];

    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [contextOrNil deleteObject:obj];
    }];

    return YES;
}

#pragma mark - Thread Safety with Main MOC
- (NSManagedObjectContext *)threadSafeContext:(NSManagedObjectContext *)context
{
    if (context == nil) {
        context = [self managedObjectContext];
    }

#ifndef DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    //For debugging only!
    if (context == [self managedObjectContext]) {
        NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"XXX ALERT ALERT XXXX\nNOT ON MAIN QUEUE!");
    }
#pragma clang diagnostic pop
#endif

    return context;
}

#pragma mark - Context Saving and Merging
- (void)saveMainContext
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveContext:[self managedObjectContext]];
    });
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error localizedDescription]);
    }
}

- (void)saveTempContext:(NSManagedObjectContext *)tempContext
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tempContextSaved:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:tempContext];

    [self saveContext:tempContext];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:tempContext];
}

- (void)tempContextSaved:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
    });
}

- (NSManagedObjectContext *)startTransaction
{
    return [self tempManagedObjectContext];
}

- (void)endTransactionForContext:(NSManagedObjectContext *)context
{
    [self saveTempContext:context];
}

#pragma mark - iCloud Integration
//THIS IS NOT CORRECT
//TODO - MAKE THIS WORK
- (void)setupiCloudForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *localStore = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:self.databaseFilename];

    //http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/Foundation/Classes/NSFileManager_Class/Reference/Reference.html#//apple_ref/occ/instm/NSFileManager/URLForUbiquityContainerIdentifier:
    NSURL *iCloud = [fileManager URLForUbiquityContainerIdentifier:nil];

    if (iCloud) {

        NSLog(@"iCloud is working");

        NSURL *iCloudLogsPath = [NSURL fileURLWithPath:[[iCloud path] stringByAppendingPathComponent:iCloudLogsDirectoryName]];

        NSLog(@"iCloudEnabledAppID = %@", self.iCloudAppId);
        NSLog(@"dataFileName = %@", self.databaseFilename);
        NSLog(@"iCloudDataDirectoryName = %@", iCloudDataDirectoryName);
        NSLog(@"iCloudLogsDirectoryName = %@", iCloudLogsDirectoryName);
        NSLog(@"iCloud = %@", iCloud);
        NSLog(@"iCloudLogsPath = %@", iCloudLogsPath);

        if ([fileManager fileExistsAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]] == NO) {
            NSError *fileSystemError;
            [fileManager createDirectoryAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]
                   withIntermediateDirectories:YES attributes:nil error:&fileSystemError];
            if (fileSystemError != nil) {
                NSLog(@"Error creating database directory %@", fileSystemError);
            }
        }

        NSString *iCloudData = [[[iCloud path]
                                 stringByAppendingPathComponent:iCloudDataDirectoryName]
                                stringByAppendingPathComponent:self.databaseFilename];

        NSLog(@"iCloudData = %@", iCloudData);

        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
        [options setObject:self.iCloudAppId forKey:NSPersistentStoreUbiquitousContentNameKey];
        [options setObject:iCloudLogsPath forKey:NSPersistentStoreUbiquitousContentURLKey];

        [psc lock];

        [psc addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil URL:[NSURL fileURLWithPath:iCloudData]
                                options:options
                                  error:nil];

        [psc unlock];
    } else {
        NSLog(@"iCloud is NOT working - using a local store");
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];

        [psc lock];

        [psc addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil
                                    URL:localStore
                                options:options
                                  error:nil];
        [psc unlock];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:VICOREDATA_NOTIFICATION_ICLOUD_UPDATED object:nil userInfo:nil];
}

- (void)mergeChangesFromiCloud:(NSNotification *)notification
{
    NSLog(@"Merging in changes from iCloud...");

    dispatch_async(dispatch_get_main_queue(), ^{
        [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];

        NSNotification *refreshNotification = [NSNotification notificationWithName:VICOREDATA_NOTIFICATION_ICLOUD_UPDATED
                                                                            object:self
                                                                          userInfo:[notification userInfo]];
        [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
    });
}

#pragma mark - Convenience Methods
- (VIManagedObjectMapper *)mapperForClass:(Class)objectClass
{
    VIManagedObjectMapper *mapper = [self.mapperCollection objectForKey:NSStringFromClass(objectClass)];
    if (!mapper) {
        mapper = [VIManagedObjectMapper defaultMapper];
    }
    
    return mapper;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)resetCoreData
{
    NSArray *stores = [[self persistentStoreCoordinator] persistentStores];

    for(NSPersistentStore *store in stores) {
        [[self persistentStoreCoordinator] removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    
    _persistentStoreCoordinator = nil;
    _managedObjectContext = nil;
    _managedObjectModel = nil;
}

- (void)debugPersistentStore
{
    NSLog(@"%@", [[_persistentStoreCoordinator managedObjectModel] entitiesByName]);
}

@end

