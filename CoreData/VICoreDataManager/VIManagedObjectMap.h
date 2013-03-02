//
//  VIManagedObjectMap.h
//  CoreData
//

#import <Foundation/Foundation.h>

@interface VIManagedObjectMap : NSObject

@property NSString *keyInput;
@property NSString *keyCoreData;

//defaults to NSString
@property Class expectedClass;

//defaults to rfc3339 like "1985-04-12T23:20:50.52Z"
@property NSDateFormatter *dateFormatter;

+ (instancetype)mapWithInput:(NSString *)inputKey output:(NSString *)outputKey;
+ (instancetype)mapWithInput:(NSString *)inputKey
                      output:(NSString *)outputKey
               expectedClass:(Class)expectedClass;
+ (instancetype)mapWithInput:(NSString *)inputKey
                      output:(NSString *)outputKey
               expectedClass:(Class)expectedClass
               dateFormatter:(NSDateFormatter *)dateFormatter;

@end
