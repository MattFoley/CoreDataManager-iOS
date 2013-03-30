//
//  VICoreDataManager.m
//  CoreData
//

#import "VICoreDataManager.h"

@interface VICoreDataManager () {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property NSString *resource;
@property NSString *databaseFilename;
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

//Convenience Methods
- (VIManagedObjectMapper *)mapperForClass:(Class)objectClass;
- (NSURL *)applicationDocumentsDirectory;
- (void)debugPersistentStore;

@end

//private interface to VIManagedObjectMapper
@interface VIManagedObjectMapper (dictionaryInputOutput)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object;
- (NSDictionary *)dictionaryRepresentationOfManagedObject:(NSManagedObject *)object;
@end

@implementation VICoreDataManager

+ (void)initialize
{
    //make sure the shared instance is ready
    [self sharedInstance];
}

+ (VICoreDataManager *)sharedInstance
{
    static VICoreDataManager *_sharedObject;
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
    [self setResource:resource database:database forBundleIdentifier:nil];
}

- (void)setResource:(NSString *)resource database:(NSString *)database forBundleIdentifier:(NSString *)bundleIdentifier
{
    //this method is publicized in unit tests
    self.resource = resource;
    self.databaseFilename = database;
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

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
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
    }
}

#pragma mark - Create and configure
- (NSManagedObject *)objectForClass:(Class)managedObjectClass inContext:(NSManagedObjectContext *)contextOrNil
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

- (NSArray *)importArray:(NSArray *)inputArray forClass:(Class)objectClass withContext:(NSManagedObjectContext*)contextOrNil;
{
    VIManagedObjectMapper *mapper = [self mapperForClass:objectClass];
    if (mapper.deleteAllBeforeImport) {
        [self deleteAllObjectsOfClass:objectClass context:contextOrNil];
    }

    NSMutableArray *returnArray = [NSMutableArray array];
    [inputArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [returnArray addObject:[self importDictionary:obj forClass:objectClass withContext:contextOrNil]];
        } else {
            NSLog(@"ERROR\n %s \nexpecting an NSArray full of NSDictionaries", __PRETTY_FUNCTION__);
        }
    }];

    return [returnArray copy];
}

- (NSManagedObject *)importDictionary:(NSDictionary *)inputDict forClass:(Class)objectClass withContext:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self threadSafeContext:contextOrNil];
    
    VIManagedObjectMapper *mapper = [self mapperForClass:objectClass];
    NSString *uniqueKey = mapper.uniqueComparisonKey;

    NSArray *existingObjectArray;
    if (uniqueKey) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ == %@", uniqueKey, [inputDict objectForKey:uniqueKey]];
        existingObjectArray = [self arrayForClass:objectClass withPredicate:predicate forContext:contextOrNil];
        NSAssert([existingObjectArray count] < 2, @"UNIQUE IDENTIFIER IS NOT UNIQUE. MORE THAN ONE MATCHING OBJECT FOUND");
    }

    NSManagedObject *returnObject;
    if ([existingObjectArray count] && mapper.overwriteObjectsWithServerChanges) {
        returnObject = existingObjectArray[0];
        [self setInformationFromDictionary:inputDict forManagedObject:returnObject];
    } else {
        returnObject = [self objectForClass:objectClass inContext:contextOrNil];
        [self setInformationFromDictionary:inputDict forManagedObject:returnObject];
    }

    return returnObject;
}

- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    VIManagedObjectMapper *mapper = [self mapperForClass:[object class]];
    [mapper setInformationFromDictionary:inputDict forManagedObject:object];
}

#pragma mark - Convenient Output
- (NSDictionary *)dictionaryRepresentationOfManagedObject:(NSManagedObject *)object
{
    return [[self mapperForClass:[object class]] dictionaryRepresentationOfManagedObject:object];
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
    if (!context) {
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

- (NSManagedObjectContext *)temporaryContext
{
    return [self tempManagedObjectContext];
}

- (void)saveAndMergeWithMainContext:(NSManagedObjectContext *)context
{
    [self saveTempContext:context];
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