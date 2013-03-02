//
//  VIPerson.m
//  CoreData
//

#import "VIPerson.h"

@implementation VIPerson

@dynamic firstName;
@dynamic lastName;



+ (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object
{
    VIPerson *person = (VIPerson *)object;

    person.firstName = [[params objectForKey:PARAM_FIRST_NAME] isKindOfClass:[NSNull class]] ? person.firstName :
    [params objectForKey:PARAM_FIRST_NAME];

    person.lastName = [[params objectForKey:PARAM_LAST_NAME] isKindOfClass:[NSNull class]] ? person.lastName :
    [params objectForKey:PARAM_LAST_NAME];
    
    return person;
}


@end
