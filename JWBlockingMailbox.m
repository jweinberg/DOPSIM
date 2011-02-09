//
//  JWBlockingQueue.m
//  Created by Joshua Weinberg on 1/26/11.
//

#import "JWBlockingMailbox.h"

@interface JWBlockingMailbox ()
@property (retain) CFMutableDictionaryRef map __attribute__((NSObject));
@property (retain) NSConditionLock *condition;
@end


@implementation JWBlockingMailbox
@synthesize map, condition;

- (id)init;
{
    if ((self = [super init]))
    {
        self.map = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)dealloc;
{
    self.map = nil;
    self.condition = nil;
    [super dealloc];
}

- (void)enqueue:(id)object from:(NSUInteger)index;
{
    [self.condition lock];
    @try
    {
        NSMutableArray *array = nil;
        if (!CFDictionaryGetValueIfPresent(self.map, (void*)index, (void*)&array))
        {
            array = [NSMutableArray array];
            CFDictionarySetValue(self.map, (void*)index, array);
        }
        [array insertObject:object atIndex:0];
        [self.condition broadcast];
    }
    @finally 
    {
        [self.condition unlock];
    }
}

- (id)dequeue:(NSInteger)index;
{
    [self.condition lock];
    id retVal = nil;
    @try 
    {
        NSMutableArray *array = (id)CFDictionaryGetValue(self.map, (void*)index);
        if ([array count] == 0)
        {
            while (1)
            {            
                [self.condition wait];              
                if (CFDictionaryGetValueIfPresent(self.map, (void*)index, (void*)&array))
                {
                    if ([array count])
                        break;
                }
            }
        }

        retVal = [[[array lastObject] retain] autorelease];
        [array removeLastObject];
    }
    @finally 
    {
        [self.condition unlock];
        return retVal;
    }
}

@end
