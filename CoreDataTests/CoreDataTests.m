//
//  CoreDataTests.m
//  CoreDataTests
//

#import "CoreDataTests.h"
#import <CoreData/CoreData.h>

#import "VIPersonDataSource.h"
#import "VIPerson.h"

//use this interface for publicizing private methods for testing
@interface VICoreDataManager(privateTests)
- (void)setResource:(NSString *)resource database:(NSString *)database forBundleIdentifier:(NSString *)bundleIdentifier;
@end

@implementation CoreDataTests

- (void)setUp
{
    [[VICoreDataManager sharedInstance] setResource:@"VICoreDataModel" database:@"VICoreDataModel.sqlite" forBundleIdentifier:@"vokal.CoreDataTests"];
}

- (void)tearDown
{
    [[VICoreDataManager sharedInstance] resetCoreData];
}

- (void)testSomething
{

    
    STAssertTrue(dataSource != nil, @"dataSource should be initialized");
}

@end