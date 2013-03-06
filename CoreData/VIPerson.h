//
//  VIPerson.h
//  CoreData
//
//  Created by Sean Wolter on 3/6/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VIPerson, VITeam;

@interface VIPerson : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) VITeam *team;
@property (nonatomic, retain) VIPerson *spouse;

@end
