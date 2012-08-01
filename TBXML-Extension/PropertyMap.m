//
// Created by Mitchell Vanderhoeff on 7/31/12.
//
// Source: http://stackoverflow.com/questions/754824/get-an-object-attributes-list-in-objective-c
//


#import <objc/runtime.h>
#import "PropertyMap.h"


@implementation PropertyMap

static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T') {
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    return "@";
}

+ (NSArray *)getPropertyNameArrayOfClass:(Class)klass {
    NSMutableArray *propertyNamesOrdered = [NSMutableArray array];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
            NSString *propertyType = [NSString stringWithCString:propType encoding:NSUTF8StringEncoding];
            [propertyNamesOrdered addObject:propertyName];
        }
    }
    free(properties);
    return propertyNamesOrdered;
}

+ (NSDictionary *)getPropertyTypeMapOfClass:(Class)klass {
    NSMutableDictionary *propertyMap = [NSMutableDictionary dictionary];
    NSMutableArray *propertyNamesOrdered = [NSMutableArray array];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
            NSString *propertyType = [NSString stringWithCString:propType encoding:NSUTF8StringEncoding];
            [propertyMap setValue:propertyType forKey:propertyName];
            [propertyNamesOrdered addObject:propertyName];
        }
    }
    free(properties);
    return propertyMap;
}

+ (NSString *)getTypeStringForProperty:(NSString *)propertyName ofClass:(Class)klass {
    return [[self getPropertyTypeMapOfClass:klass] valueForKey:propertyName];
}
@end