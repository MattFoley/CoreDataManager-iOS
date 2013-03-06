//
//  VIViewController.m
//  CoreData
//

#import "VIViewController.h"
#import "VICoreDataManager.h"
#import "VIPerson.h"
#import "VITeam.h"

@interface VIViewController ()

@end

@implementation VIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupDataSource];
    
    [self initializeCoreData];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self
                                                                                           action:@selector(reloadData)];
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

    self.dataSource = [[VIPersonDataSource alloc] initWithPredicate:nil cacheName:nil tableView:self.tableView
                                                 sectionNameKeyPath:nil sortDescriptors:sortDescriptors
                                                 managedObjectClass:[VIPerson class]];
}

- (void)reloadData {
    [self.dataSource reloadData];
}

- (void)initializeCoreData
{
    [[VICoreDataManager sharedInstance] resetCoreData];

    id thing = [VIPerson addWithDictionary:[self makePersonDict] forManagedObjectContext:nil];
    NSLog(@"here's the thing %@",thing);
}

- (NSDictionary *)makePersonDict
{
    NSDictionary *spoutDict = @{@"firstName" : @"Lisa" ,
                                @"lastName" : @"Frank" };

    NSDictionary *teamDict = @{@"teamName" : @"Sponges" };

    NSDictionary *dict = @{@"firstName" : @"Bob" ,
                           @"lastName" : @"Frank" ,
                           @"team" : teamDict ,
                           @"spouse" : spoutDict };
    return dict;
}

@end
