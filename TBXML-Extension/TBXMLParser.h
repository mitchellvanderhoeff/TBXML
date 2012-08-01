//
// Created by mitch on 7/29/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "TBXML.h"

@class TBXML;
@class NSManagedObject;


@interface TBXMLParser : NSObject
+ (void)populateXMLMessageWrapper:(id)xmlMessageWrapper withXMLString:(NSString *)xmlString withPathFromRoot:(NSString *)pathFromRoot;

@end