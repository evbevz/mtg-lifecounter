//
//  ThrowDiceEngine.h
//  MTG LifeCounter
//
//  Created by Mac on 06.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThrowDiceEngine : NSObject
{
    CGRect  field;
    CGPoint startPoint;
    CGPoint endPoint;
    float   initialVelocity;
    float   velocityFading;
}

@property(nonatomic, readwrite) CGRect  field;
@property(nonatomic, readwrite) CGPoint startPoint;
@property(nonatomic, readwrite) CGPoint endPoint;
@property(nonatomic, readwrite) float   initialVelocity;    // start velocity (pixel/sec)
@property(nonatomic, readwrite) float   velocityFading;     // negative acceleration (pixel/sec^2)


// returns array of dicts(key/value) of end_point/duration
- (NSMutableArray*) GetPath;

@end
