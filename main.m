#import <Foundation/Foundation.h>
#import "DOPSIM.h"


int p = 3;

double alpha = 0.001;
double a = 0.1; //.mm
double h = 1.0; //.minutes
int n = 12;
int n_timesteps = 1000;

int main (int argc, const char * argv[]) 
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [DOPSIM doPSIM:p topology:switchTopology block:^(DOPSIM * psim) {
		NSMutableArray *u = [NSMutableArray array];
		if (psim.rank == 0)
		{
			for (int i = 0; i < n; ++i)
			{
				[u addObject:[NSNumber numberWithFloat:(i==0?200.0f:0.0f)]];
			}
		}
		u = [NSMutableArray arrayWithArray:[psim scatter:u from:0]];
		NSUInteger n_local = [u count];
		[u insertObject:[NSNumber numberWithFloat:0] atIndex:0];
		[u addObject:[NSNumber numberWithFloat:0]];
		
		NSMutableArray *v = [NSMutableArray arrayWithArray:u];
		
		for (int t = 0; t < n_timesteps; ++t)
		{
			if (psim.rank > 0)
				[psim send:[u objectAtIndex:1] to:psim.rank-1];
			if (psim.rank < [psim numberOfNodes]-1)
				[psim send:[u objectAtIndex:[u count] - 2] to:psim.rank+1];
			if (psim.rank > 0)
				[u replaceObjectAtIndex:0 withObject:[psim receive:psim.rank-1]];
			if (psim.rank < [psim numberOfNodes]-1)
				[u replaceObjectAtIndex:[u count] - 1 withObject:[psim receive:psim.rank+1]];
			
			for (int i = 1; i < 1 + n_local; ++i)
			{
				NSUInteger j = i + n_local*psim.rank-1;
				if (j > 0 && j < n-1)
				{
					CGFloat next = [[u objectAtIndex:i+1] floatValue];
					CGFloat prev = [[u objectAtIndex:i-1] floatValue];
					CGFloat current = [[u objectAtIndex:i] floatValue];
					
					CGFloat val = alpha*h/(a*a)*(next-2.0*current+prev)+current;
					[v replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:val]];
				}
			}
			id tmp = v;
			v = u;
			u = tmp;
			if (psim.rank == 1)
				NSLog(@"%d) %@", t, [u objectAtIndex:3]);
		}
		
    }];
    
    [pool drain];
    return 0;
}
