//
// Created by mitchellvanderhoeff on 7/29/12.
//
//


#import "TBXMLParser.h"
#import "PropertyMap.h"

@implementation TBXMLParser

/*!
    @function populateXMLWrapper:withXMLString:withPathFromRoot:
    @abstract Populates an XML wrapper with an XML string recursively and unknowing of the properties of that wrapper.
    @discussion This function traverses the path, finds the base element and then recursively loops through all the child elements.
     During this process, each element tries to
      1) instantiate any classes it can find in the element names. If the element name itself is not a class name, it will try to infer the class from the XML wrapper class.
      2) try to set itself as the value of its parent object's property. If the parent is an array or a dictionary, it will try to add itself to its parent object instead.
     This way, you can nest as many elements as you want in the XML. Elements don't need to be properties of the parent object, all that happens is an 'INVALID' log message.


    @param xmlWrapper
     The wrapper that needs to be populated. Its properties can only be of the following types:
     NSString, NSArray, NSMutableArray, NSDictionary, NSMutableDictionary, or another XML wrapper containing these types.
    @param xmlString
     The XML string that is to be parsed. This string must contain elements with names identical to the property names of xmlWrapper.
     Types are inferred and therefore don't need to be passed in the string.
    @param pathFromRoot
     This path must lead to the element that contains properties, which the method will use to populate the xmlWrapper.
 */

+ (void)populateXMLWrapper:(id)xmlWrapper withXMLString:(NSString *)xmlString withPathFromRoot:(NSString *)pathFromRoot {
    NSLog(@"--> Parsing for XML Message Wrapper %@ started. Path from root: '%@'.", xmlWrapper, pathFromRoot);
    TBXML* tbxml = [TBXML newTBXMLWithXMLString:xmlString error:nil];
    TBXMLElement *rootElement = [tbxml rootXMLElement];

            // Insert custom query here. Format is element names separated by periods (.)
                                                    // The paths should end up at the base element where all the wrapper properties are located
    __block BOOL elementFound = NO;

    [TBXML iterateElementsForQuery:pathFromRoot
                       fromElement:rootElement
                         withBlock:^(TBXMLElement *element) {
                             elementFound = YES;
                             [self populateObject:xmlWrapper fromTBXMLElement:element];
                         }];
    if (!elementFound) {
        NSLog(@"ERROR: Element not found. Check your path (%@).", pathFromRoot);
        return;
    }

    NSLog(@"--> Parsing for XML Message Wrapper %@ finished", xmlWrapper);


}

+ (NSString *)elementNameStripNamespace:(TBXMLElement *)element {
    return [[[TBXML elementName:element] componentsSeparatedByString:@":"] lastObject];
}

+ (void)trySetValue:(id)value forKey:(NSString *)key onObject:(id)object {
    if ([object respondsToSelector:NSSelectorFromString(key)] && [object validateValue:&value forKey:key error:nil]) {
        [object setValue:value forKey:key];
        NSLog(@"*value '%@' for key %@ set on object %@", value, key, object);
    } else {
        NSLog(@"INVALID value '%@' for key %@ on object %@.\n"
                "Either %@ is not a property of %@ or '%@' is not a valid value for it.",
                value, key, object, key, object, value);
    }
}

+ (void)trySetObject:(id)selfObject withKey:(NSString *)elementName onParentObject:(id)parentObject {
    if ([parentObject isKindOfClass:[NSMutableArray class]]) {                // parent is a Mutable array
        [parentObject addObject:selfObject];
        NSLog(@"*added object '%@' to array", selfObject);
    } else if ([parentObject isKindOfClass:[NSMutableDictionary class] ]){    // parent is a Mutable dictionary
        [parentObject setValue:selfObject forKey:elementName];
        NSLog(@"*set value '%@' for key '%@' on dictionary", selfObject, elementName);
    } else {
        [self trySetValue:selfObject                                          // parent is a wrapper
                   forKey:elementName
                 onObject:parentObject];
    }

}

+ (NSString *)getTypeForPropertyName:(NSString *)propertyName forClass:(Class)klass {
    NSString *propertyType = [PropertyMap getTypeStringForProperty:propertyName ofClass:klass];
    if ([propertyType isEqualToString:@"NSArray"])
        propertyType = @"NSMutableArray";
    else if ([propertyType isEqualToString:@"NSDictionary"])
        propertyType = @"NSMutableDictionary";
    else if (!propertyType)
        propertyType = propertyName;
    return propertyType;
}

+ (void)populateObject:(id)parentObject fromTBXMLElement:(TBXMLElement *)element {
    NSString *const elementName = [self elementNameStripNamespace:element];

    TBXMLElement *childElement = element->firstChild;

    if (childElement) {                                                                    // this element has a child
        id selfObject;
        if ([[TBXML elementName:childElement] isEqualToString:@"entry"]) {                 // this is a generic dictionary
            selfObject = [NSMutableDictionary dictionary];
            NSLog(@"*object with class NSMutableDictionary instantiated");
        } else if ([elementName isEqualToString:@"entry"]) {                      // this is a generic dictionary entry
            TBXMLElement *value = [TBXML childElementNamed:@"value"
                                           parentElement:element];
            TBXMLElement *valueChild = value->firstChild;
            if (valueChild) {                                                    // the value is a wrapper itself
                [self populateObject:parentObject fromTBXMLElement:valueChild];
            } else {
                TBXMLElement *key = [TBXML childElementNamed:@"key"              // the value is a string
                                               parentElement:element];
                NSString *const keyString = [TBXML textForElement:key];
                NSString *const valueString = [TBXML textForElement:value];
                [self trySetObject:valueString
                           withKey:keyString
                    onParentObject:parentObject];
            }
            return;
        } else {                                                                                        // this is a list or a wrapper
            NSString *const elementType = [self getTypeForPropertyName:elementName forClass:[parentObject class]];
            Class elementObjectClass = NSClassFromString(elementType);
            if (elementObjectClass) {
                selfObject = [[elementObjectClass alloc] init];
                NSLog(@"*object with class %@ instantiated", elementObjectClass);
            } else {
                NSLog(@"ERROR: Could not find class '%@'. Check the XML element named '%@'.", elementType, elementName);
                return;
            }
        }
        do {
            [self populateObject:selfObject
                fromTBXMLElement:childElement];
        } while ((childElement = childElement->nextSibling));
        [self trySetObject:selfObject
                   withKey:elementName
            onParentObject:parentObject];
    } else {
        [self trySetObject:[TBXML textForElement:element]
                withKey:elementName
         onParentObject:parentObject];
    }
}



@end