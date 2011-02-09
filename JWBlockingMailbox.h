//
//  JWBlockingQueue.h
//  Created by Joshua Weinberg on 1/26/11.
//

#import <Cocoa/Cocoa.h>


@interface JWBlockingMailbox : NSObject 
- (void)enqueue:(id)object from:(NSUInteger)index;
- (id)dequeue:(NSInteger)index;
@end
