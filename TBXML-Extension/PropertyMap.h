//
// Created by mitch on 7/31/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface PropertyMap : NSObject
+ (NSArray *)getPropertyNameArrayOfClass:(Class)klass;

+ (NSDictionary *)getPropertyTypeMapOfClass:(Class)klass;

+ (NSString *)getTypeStringForProperty:(NSString *)propertyName ofClass:(Class)klass;


@end