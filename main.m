#import <Foundation/Foundation.h>
#import "DOPSIM.h"

int m = 1000000;
int p = 4;

NSUInteger scalar_product(NSRange a, NSRange b)
{
    NSUInteger acc = 0;
    for (int i = 0; i < a.length; ++i)
    {
        acc += (a.location + i) * (b.location + i);
    }
    return acc;
}

int main (int argc, const char * argv[]) 
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [DOPSIM doPSIM:p topology:switchTopology block:^(DOPSIM * psim) {
        NSUInteger length = m/p;
        if (psim.rank == 0)
        {
            for (int j = 1; j < p; ++j)
            {
                NSValue *a = [NSValue valueWithRange:NSMakeRange(length*j, length)];
                NSValue *b = [NSValue valueWithRange:NSMakeRange(length*j, length)];      
                [psim send:a to:j];
                [psim send:b to:j];
            }
            NSUInteger a = scalar_product(NSMakeRange(0, length), NSMakeRange(0, length));
            for (int j = 1; j < p; ++j)
            {
                a += [[psim receive:j] unsignedIntegerValue];
            }
            NSLog(@"%lu", a);
        }
        else
        {
            NSValue *pa = [psim receive:0];
            NSValue *pb = [psim receive:0];
            NSUInteger val = scalar_product([pa rangeValue], [pb rangeValue]);
            [psim send:[NSNumber numberWithUnsignedInteger:val] to:0];
        }
       
    }];
    
    [pool drain];
    return 0;
}
