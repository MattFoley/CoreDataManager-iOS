//
//  VIViewController.m
//  CoreData
//

#import "VIViewController.h"
#import "VICoreDataManager.h"
#import "VIPerson.h"

@interface VIViewController ()

@end

@implementation VIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//
//    [self initializeCoreData];
//
//    [self setupDataSource];
//    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
//                                                                                           target:self
//                                                                                           action:@selector(reloadData)];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)setupDataSource
{
    NSArray *sortDescriptors = [NSArray arrayWithObjects:
            [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
            [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES], nil];

    self.dataSource = [[VIPersonDataSource alloc]initWithPredicate:nil cacheName:nil tableView:self.tableView
                                                 sectionNameKeyPath:nil sortDescriptors:sortDescriptors
                                                 managedObjectClass:[VIPerson class]];
}

- (void)reloadData {
    [self.dataSource reloadData];
}

- (void)initializeCoreData
{
    [[VICoreDataManager sharedInstance] resetCoreData];

    //MAKE 20 PEOPLE WITH THE DEFAULT MAPPER
    int i = 0;
    while (i < 21 ) {
        NSLog(@"%@",[VIPerson addWithDictionary:[self makePersonDictForDefaultMapper] forManagedObjectContext:nil]);
        i++;
    }


    //MAKE 20 PEOPLE WITH A CUSTOM MAPPER
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd' 'LLL' 'yy' 'HH:mm"];
    [df setTimeZone:[NSTimeZone localTimeZone]];

    NSArray *maps = @[[VIManagedObjectMap mapWithInput:@"first" output:@"firstName"],
                      [VIManagedObjectMap mapWithInput:@"last" output:@"lastName"],
                      [VIManagedObjectMap mapWithInput:@"date_of_birth" output:@"birthDay" dateFormatter:df],
                      [VIManagedObjectMap mapWithInput:@"cat_num" output:@"numberOfCats"],
                      [VIManagedObjectMap mapWithInput:@"CR_PREF" output:@"lovesCoolRanch"]];
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:@"lastName" andMaps:maps];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];

    int j = 0;
    while (j < 21 ) {
        NSLog(@"%@",[VIPerson addWithDictionary:[self makePersonDictForCustomMapper] forManagedObjectContext:nil]);
        j++;
    }

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"lovesCoolRanch == %@", @YES];
    NSArray *allPeople = [VIPerson fetchAllForPredicate:pred forManagedObject:nil];

    [allPeople enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = [obj dictionaryRepresentation];
        NSLog(@"%@",dict);
    }];
}

- (NSString *)randomNumber
{
    return [NSString stringWithFormat:@"%d",arc4random()%3000];
}

- (NSDictionary *)makePersonDictForDefaultMapper
{
    NSDictionary *dict = @{@"firstName" :  [self randomNumber],
                           @"lastName" : [self randomNumber] ,
                           @"birthDay" : @"1983-07-24T03:22:15Z",
                           @"numberOfCats" : @17,
                           @"lovesCoolRanch" : @NO};
    return dict;
}

- (NSDictionary *)makePersonDictForCustomMapper
{
    NSDictionary *dict = @{@"first" :  [self randomNumber],
                           @"last" : [self randomNumber] ,
                           @"date_of_birth" : @"24 Jul 83 14:16",
                           @"cat_num" : @17,
                           @"CR_PREF" : @YES};
    return dict;
}

@end
