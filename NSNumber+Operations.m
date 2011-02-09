//
//  NSNumber+Operations.m
//  DOPSIM
//
//  Created by Joshua Weinberg on 1/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSNumber+Operations.h"


@implementation NSNumber (Operations)

- (NSNumber*)add:(NSNumber*)other;
{
    const char * type = [self objCType];
    if (strcmp(type, @encode(float)))
        return [NSNumber numberWithFloat:[self floatValue] + [other floatValue]];
    else if (strcmp(type, @encode(double)))
        return [NSNumber numberWithDouble:[self doubleValue] + [other doubleValue]];
    else if (strcmp(type, @encode(char)))
        return [NSNumber numberWithChar:[self charValue] + [other charValue]];
    else if (strcmp(type, @encode(int)))
        return [NSNumber numberWithInt:[self intValue] + [other intValue]];
    else if (strcmp(type, @encode(short)))
        return [NSNumber numberWithShort:[self shortValue] + [other shortValue]];
    //and so forth
    return nil;
}

@end
