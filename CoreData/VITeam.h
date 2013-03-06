//
//  VITeam.h
//  CoreData
//
//  Created by Sean Wolter on 3/6/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VIPerson;

@interface VITeam : NSManagedObject

@property (nonatomic, retain) NSString * teamName;
@property (nonatomic, retain) VIPerson *teamMembers;

@end
