//
//  VIPerson.h
//  CoreData
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VICoreDataManager.h"

static NSString *const PARAM_FIRST_NAME = @"serverFirstName";
static NSString *const PARAM_LAST_NAME = @"serverLastName";

@interface VIPerson : NSManagedObject

@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;

@end