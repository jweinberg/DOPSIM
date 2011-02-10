//
//  DOPSIM.h
//  Created by Joshua Weinberg on 1/26/11.
//

#import <Cocoa/Cocoa.h>
@class DOPSIM;

typedef void (^JWPSIMBody)(DOPSIM*);
typedef BOOL (^JWTopology)(NSUInteger, NSUInteger);
typedef NSNumber* (^JWReduceOp)(NSNumber*, NSNumber*);

extern JWTopology busTopology;
extern JWTopology switchTopology;
extern JWTopology (^mesh1DTopology)(NSUInteger size);
extern JWTopology (^torus1DTopology)(NSUInteger size);

extern JWReduceOp addOperation;
extern JWReduceOp multiplyOperation;
extern JWReduceOp maxOperation;
extern JWReduceOp minOperation;

@interface DOPSIM : NSObject
@property (readonly, assign) NSUInteger rank;
@property (readonly, assign) NSUInteger numberOfNodes;
- (oneway void)send:(id)data to:(NSUInteger)aRank;
- (id)oneToAllBroadcast:(id)data from:(NSUInteger)source;
- (id)allToOneCollect:(id)data to:(NSUInteger)destination;
- (id)allToAllBroadcast:(id)data;
- (id)allToOneReduce:(id)value to:(NSUInteger)destination operation:(JWReduceOp)op;
- (id)allToAllReduce:(id)value operation:(JWReduceOp)op;
- (id)receive:(NSUInteger)aRank;
- (id)scatter:(NSArray*)value from:(NSUInteger)source;
- (id)gather:(NSArray*)value to:(NSUInteger)destination;
+ (void)doPSIM:(NSUInteger)count topology:(JWTopology)topology block:(JWPSIMBody)body;
@end
