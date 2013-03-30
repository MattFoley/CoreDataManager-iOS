//
//  CoreDataTests.m
//  CoreDataTests
//

#import "ManagedObjectAdditionTests.h"
#import "VICoreDataManager.h"
#import "VIPerson.h"

NSString *const FIRST_NAME_DEFAULT_KEY = @"firstName";
NSString *const LAST_NAME_DEFAULT_KEY = @"lastName";
NSString *const BIRTHDAY_DEFAULT_KEY = @"birthDay";
NSString *const CATS_DEFAULT_KEY = @"numberOfCats";
NSString *const COOL_RANCH_DEFAULT_KEY = @"lovesCoolRanch";

NSString *const FIRST_NAME_CUSTOM_KEY = @"first";
NSString *const LAST_NAME_CUSTOM_KEY = @"last";
NSString *const BIRTHDAY_CUSTOM_KEY = @"date_of_birth";
NSString *const CATS_CUSTOM_KEY = @"cat_num";
NSString *const COOL_RANCH_CUSTOM_KEY = @"CR_PREF";

//use this interface for publicizing private methods for testing
@interface VICoreDataManager(privateTests)
- (void)setResource:(NSString *)resource database:(NSString *)database forBundleIdentifier:(NSString *)bundleIdentifier;
@end

@implementation ManagedObjectAdditionTests

- (void)setUp
{
    [[VICoreDataManager sharedInstance] setResource:@"VICoreDataModel" database:@"VICoreDataModel.sqlite"];
}

- (void)tearDown
{
    [[VICoreDataManager sharedInstance] resetCoreData];
}

- (void)testImportDictionaryWithDefaultMapper
{
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForDefaultMapper] forManagedObjectContext:nil];
    [self checkDefaultMappingForPerson:person];

    NSDictionary *dict = [person dictionaryRepresentation];
    STAssertTrue([dict isEqualToDictionary:[self makePersonDictForDefaultMapper]], @"dictionary representation failed to match input dictionary");
}

- (void)testImportDictionaryWithCustomMapper
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapper] forManagedObjectContext:nil];
    [self checkCustomMappingForPerson:person];

    NSDictionary *dict = [person dictionaryRepresentation];
    STAssertTrue([dict isEqualToDictionary:[self makePersonDictForCustomMapper]], @"dictionary representation failed to match input dictionary");
}

- (void)testImportArrayWithCustomMapper
{
    NSArray *array = @[[self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper]];
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    NSArray *arrayOfPeople = [VIPerson addWithArray:array forManagedObjectContext:nil];

    STAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");

    [arrayOfPeople enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self checkCustomMappingForPerson:obj];
    }];
}

- (void)testImportArrayWithDefaultMapper
{
    NSArray *array = @[[self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper]];
    NSArray *arrayOfPeople = [VIPerson addWithArray:array forManagedObjectContext:nil];

    STAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");

    [arrayOfPeople enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self checkDefaultMappingForPerson:obj];
    }];
}

- (void)testUniqueKeyCustomMapper
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:LAST_NAME_DEFAULT_KEY andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    
    NSDictionary *dict1 = @{FIRST_NAME_CUSTOM_KEY : @"SOMEGUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @192,
                            COOL_RANCH_CUSTOM_KEY : @YES};
    [VIPerson addWithDictionary:dict1 forManagedObjectContext:nil];
    
    NSDictionary *dict2 = @{FIRST_NAME_CUSTOM_KEY : @"SOMEGUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY2",
                            BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @192,
                            COOL_RANCH_CUSTOM_KEY : @YES};
    [VIPerson addWithDictionary:dict2 forManagedObjectContext:nil];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"firstName == %@",  @"SOMEGUY"];
    NSArray *array = [VIPerson fetchAllForPredicate:pred forManagedObject:nil];
    STAssertTrue([array count] == 2, @"unique person test array has incorrect number of people");

    NSDictionary *dict3 = @{FIRST_NAME_CUSTOM_KEY : @"ANOTHERGUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"18 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @14,
                            COOL_RANCH_CUSTOM_KEY : @YES};
    [VIPerson addWithDictionary:dict3 forManagedObjectContext:nil];

    pred = [NSPredicate predicateWithFormat:@"lastName == %@",  @"GUY1"];
    array = [VIPerson fetchAllForPredicate:pred forManagedObject:nil];
    STAssertTrue([array count] == 1, @"unique key was not effective");
    STAssertTrue([[array[0] numberOfCats] isEqualToNumber:@14], @"unique key was effective but the person object was not updated");
}

#pragma mark - Convenience stuff
- (void)checkDefaultMappingForPerson:(VIPerson *)person
{
    NSDictionary *dict = [self makePersonDictForDefaultMapper];
    STAssertTrue(person != nil, @"person was not created");
    STAssertTrue([person isKindOfClass:[VIPerson class]], @"person is wrong class");
    STAssertTrue([person.firstName isEqualToString:[dict objectForKey:FIRST_NAME_DEFAULT_KEY]], @"person first name is incorrect");
    STAssertTrue([person.lastName isEqualToString:[dict objectForKey:LAST_NAME_DEFAULT_KEY]], @"person last name is incorrect");
    STAssertTrue([person.numberOfCats isEqualToNumber:[dict objectForKey:CATS_DEFAULT_KEY]], @"person number of cats is incorrect");
    STAssertTrue([person.lovesCoolRanch isEqualToNumber:[dict objectForKey:COOL_RANCH_DEFAULT_KEY]], @"person lovesCoolRanch is incorrect");

    NSDate *birthdate = [[VIManagedObjectMap defaultDateFormatter] dateFromString:[dict objectForKey:BIRTHDAY_DEFAULT_KEY]];
    STAssertTrue([person.birthDay isEqualToDate:birthdate], @"person birthdate is incorrect");
}

- (void)checkCustomMappingForPerson:(VIPerson *)person
{
    NSDictionary *dict = [self makePersonDictForCustomMapper];
    STAssertTrue(person != nil, @"person was not created");
    STAssertTrue([person isKindOfClass:[VIPerson class]], @"person is wrong class");
    STAssertTrue([person.firstName isEqualToString:[dict objectForKey:FIRST_NAME_CUSTOM_KEY]], @"person first name is incorrect");
    STAssertTrue([person.lastName isEqualToString:[dict objectForKey:LAST_NAME_CUSTOM_KEY]], @"person last name is incorrect");
    STAssertTrue([person.numberOfCats isEqualToNumber:[dict objectForKey:CATS_CUSTOM_KEY]], @"person number of cats is incorrect");
    STAssertTrue([person.lovesCoolRanch isEqualToNumber:[dict objectForKey:COOL_RANCH_CUSTOM_KEY]], @"person lovesCoolRanch is incorrect");

    NSDate *birthdate = [[self customDateFormatter] dateFromString:[dict objectForKey:BIRTHDAY_CUSTOM_KEY]];
    STAssertTrue([person.birthDay isEqualToDate:birthdate], @"person birthdate is incorrect");
}

- (NSString *)randomNumberString
{
    return [NSString stringWithFormat:@"%d",arc4random()%3000];
}

- (NSDictionary *)makePersonDictForDefaultMapper
{
    NSDictionary *dict = @{FIRST_NAME_DEFAULT_KEY :  @"BILLY",
                           LAST_NAME_DEFAULT_KEY : @"TESTCASE" ,
                           BIRTHDAY_DEFAULT_KEY : @"1983-07-24T03:22:15Z",
                           CATS_DEFAULT_KEY : @17,
                           COOL_RANCH_DEFAULT_KEY : @NO};
    return dict;
}

- (NSDictionary *)makePersonDictForCustomMapper
{
    NSDictionary *dict = @{FIRST_NAME_CUSTOM_KEY : @"CUSTOM",
                           LAST_NAME_CUSTOM_KEY : @"MAPMAN",
                           BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                           CATS_CUSTOM_KEY : @192,
                           COOL_RANCH_CUSTOM_KEY : @YES};
    return dict;
}

- (NSDateFormatter *)customDateFormatter
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd' 'LLL' 'yy' 'HH:mm"];
    [df setTimeZone:[NSTimeZone localTimeZone]];
    return df;
}

- (NSArray *)customMapsArray
{
    return @[[VIManagedObjectMap mapWithInput:FIRST_NAME_CUSTOM_KEY output:FIRST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithInput:LAST_NAME_CUSTOM_KEY output:LAST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithInput:BIRTHDAY_CUSTOM_KEY output:BIRTHDAY_DEFAULT_KEY dateFormatter:[self customDateFormatter]],
             [VIManagedObjectMap mapWithInput:CATS_CUSTOM_KEY output:CATS_DEFAULT_KEY],
             [VIManagedObjectMap mapWithInput:COOL_RANCH_CUSTOM_KEY output:COOL_RANCH_DEFAULT_KEY]];
}

@end