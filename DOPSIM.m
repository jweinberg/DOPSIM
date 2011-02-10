//
//  DOPSIM.m
//  Created by Joshua Weinberg on 1/26/11.
//

#import "DOPSIM.h"
#import "JWBlockingMailbox.h"
#import "NSNumber+Operations.h"

JWTopology busTopology = ^(NSUInteger a, NSUInteger b){return YES;};
JWTopology switchTopology = ^(NSUInteger a, NSUInteger b){return YES;};
JWTopology (^mesh1DTopology)(NSUInteger size) = ^(NSUInteger size) {
    return (JWTopology)[[^(NSUInteger i, NSUInteger j){
        NSUInteger x = i-j;
        return (BOOL)(powl(x, x) == 1);
    } copy] autorelease];
};

JWTopology (^torus1DTopology)(NSUInteger size) = ^(NSUInteger size) {
    return (JWTopology)[[^(NSUInteger i, NSUInteger j){
        return (BOOL)((i-j+size)%size==1 || (j-i+size)%size==1);
    } copy] autorelease];
};

//JWTopology (^mesh2DTopology)(NSUInteger size) = ^(NSUInteger size) {
//    NSUInteger q = sqrt(size) + .1;
//    return (JWTopology)[[^(NSUInteger i, NSUInteger j){
//        NSUInteger x = i-j;
//        return (BOOL)(powl(x, x) == 1);
//    } copy] autorelease];
//};
//

JWReduceOp addOperation = ^(NSNumber *a, NSNumber *b){return [a add:b];};
JWReduceOp multiplyOperation = ^(NSNumber *a, NSNumber * b){return [NSNumber numberWithUnsignedInteger:[a unsignedIntegerValue] + [b unsignedIntegerValue]];};
JWReduceOp maxOperation = ^(NSNumber * a, NSNumber * b){ return [a compare:b] == NSOrderedAscending ? b : a; };
JWReduceOp minOperation =  ^(NSNumber * a, NSNumber * b){ return [a compare:b] == NSOrderedAscending ? a : b; };


@interface DOPSIM ()
- (void)bufferData:(id)data from:(NSUInteger)index;
@property (retain) JWBlockingMailbox *queue;
@property (copy) JWTopology topology;
@property (assign) NSUInteger numberOfNodes;
@property (assign) NSUInteger rank;
@end

@implementation DOPSIM
@synthesize rank, queue, topology, numberOfNodes;

- (id)initWithRank:(NSUInteger)aRank;
{
    if ((self = [super init]))
    {
        self.rank = aRank;
        self.queue = [[[JWBlockingMailbox alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc;
{
    self.queue = nil;
    self.topology = nil;
    [super dealloc];
}

- (void)send:(id)data to:(NSUInteger)aRank;
{
    if (!self.topology(aRank, self.rank))
        @throw [NSException exceptionWithName:@"NonConnectedNodes" reason:@"Selected topology doesn't allow this connection" userInfo:nil];
    id proxy = nil;
    if (aRank == self.rank)
        proxy = self;
    else
        proxy = [NSConnection rootProxyForConnectionWithRegisteredName:[NSString stringWithFormat:@"PSIM_%ul", aRank] host:nil];
    [proxy bufferData:data from:self.rank];
}

- (void)bufferData:(id)data from:(NSUInteger)index;
{
    [self.queue enqueue:data from:index];
}

- (id)receive:(NSUInteger)aRank;
{
    if (!self.topology(aRank, self.rank))
        @throw [NSException exceptionWithName:@"NonConnectedNodes" reason:@"Selected topology doesn't allow this connection" userInfo:nil];
    return [self.queue dequeue:aRank];
}

- (id)oneToAllBroadcast:(id)data from:(NSUInteger)source;
{
    if (self.rank == source)
    {
        for (int i = 0; i < self.numberOfNodes; ++i)
        {
            if (i != self.rank)
                [self send:data to:i];
        }
    }
    else
    {
        data = [self receive:source];
    }
    return data;
}

- (id)allToOneCollect:(id)data to:(NSUInteger)destination;
{
    NSMutableArray *array = [NSMutableArray array];
    [self send:data to:destination];
    if (self.rank == destination)
    {
        for (NSUInteger i = 0; i < self.numberOfNodes; ++i)
        {
            [array addObject:[self receive:i]];
        }
    }
    return array;
}

- (id)allToAllBroadcast:(id)data;
{
    NSMutableArray *array = [self allToOneCollect:data to:0];
    array = [self oneToAllBroadcast:array from:0];
    return array;
}

- (id)allToOneReduce:(id)value to:(NSUInteger)destination operation:(JWReduceOp)op;
{
    id result = nil;
    [self send:value to:destination];
    if (self.rank == destination)
    {
        result = [self receive:0];
        for (int i = 1; i < self.numberOfNodes; ++i)
        {
            id other = [self receive:i];
            result = op(result, other);
        }
    }
    return result;
}

- (id)allToAllReduce:(id)value operation:(JWReduceOp)op;
{
    id result = [self allToOneReduce:value to:0 operation:op];
    result = [self oneToAllBroadcast:result from:0];
    return result;
}

- (id)scatter:(NSArray*)value from:(NSUInteger)source;
{
	NSUInteger p = self.numberOfNodes;
	if (self.rank == source)
	{
		NSUInteger n = [value count]/p;
		for (int i = 0; i < p-1; ++i)
			[self send:[value subarrayWithRange:NSMakeRange(i*n, n)]
					to:i];
		[self send:[value subarrayWithRange:NSMakeRange(n*(p-1), [value count] - n*(p-1))]
				to:p-1];
	}
	return [self receive:source];
}

- (id)gather:(NSArray*)value to:(NSUInteger)destination;
{
	NSUInteger p = self.numberOfNodes;
	NSMutableArray *result = [NSMutableArray array];
	[self send:value to:destination];
	if (self.rank == destination)
	{
		for (int i = 0; i < p; ++i)
		{
			[result addObjectsFromArray:[self receive:i]];
		}
	}
	return result;
}

static NSUInteger runningThreads = 0;

+ (void)beginThread:(NSArray*)args;
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSConnection *connection = [args objectAtIndex:0];
    DOPSIM *psim = [args objectAtIndex:1];
    JWPSIMBody body = [args objectAtIndex:2];    
    [connection setRootObject:psim];
    body(psim);
    
    NSCondition *lock = [args objectAtIndex:3];
    [lock lock];
    runningThreads--;
    [lock signal];
    [lock unlock];
    [pool drain];
}

+ (void)doPSIM:(NSUInteger)count topology:(JWTopology)topology block:(JWPSIMBody)body;
{
    NSMutableArray *workers = [NSMutableArray array];
    NSCondition *condition = [[NSCondition alloc] init];
    
    [condition lock];
    
    for (int i = 0; i < count; ++i)
    {
        NSConnection *con = [[NSConnection alloc] init];
        [con registerName:[NSString stringWithFormat:@"PSIM_%ul", i]];
        [con runInNewThread];
        
        DOPSIM *psim = [[DOPSIM alloc] initWithRank:i];
        psim.topology = topology;
        psim.numberOfNodes = count;
        NSArray *args = [NSArray arrayWithObjects:con, psim, body, condition, nil];        
        [workers addObject:args];
        [psim release];
        [con release];
    }
    
    runningThreads = count;
    
    for (NSArray *args in workers)
    {
        [NSThread detachNewThreadSelector:@selector(beginThread:) toTarget:self withObject:args];
    }
    
    while (runningThreads > 0)
    {
        [condition wait];
    }
    
    [condition unlock];
    [condition release];
}

@end
