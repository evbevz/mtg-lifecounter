//
//  ThrowDiceEngine.m
//  MTG LifeCounter
//
//  Created by Mac on 06.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ThrowDiceEngine.h"

@implementation ThrowDiceEngine

@synthesize startPoint;
@synthesize endPoint;
@synthesize field;
@synthesize initialVelocity;
@synthesize velocityFading;


-(NSMutableArray*) GetPath
{
    NSMutableArray *path = [[NSMutableArray alloc] init];
    
    CGRect testField = CGRectMake(field.origin.x - 1, field.origin.y - 1, field.size.width + 2, field.size.height + 2);
    
    float velocity = initialVelocity;
    CGPoint currentPoint = endPoint;
    CGPoint prevPoint = startPoint;
    
    while(velocity > 0)
    {
        
        float A1 = prevPoint.y - currentPoint.y;
        float B1 = currentPoint.x - prevPoint.x;
        float C1 = prevPoint.x * currentPoint.y - currentPoint.x * prevPoint.y;

        // lets find lines
        CGPoint point1;
        CGPoint point2;
        CGPoint point3;
        
        if(currentPoint.x > prevPoint.x)
            point1.x = field.origin.x + field.size.width;
        else
            point1.x = field.origin.x;
        
        if(currentPoint.y > prevPoint.y)
            point1.y = field.origin.y + field.size.height;
        else
            point1.y = field.origin.y;
            
        point2.x = (point1.x == field.origin.x ? (field.origin.x + field.size.width) : field.origin.x);
        point2.y = point1.y;
            
        point3.x = point1.x;
        point3.y = (point1.y == field.origin.y ? (field.origin.y + field.size.height) : field.origin.y);
        
        CGPoint crossPoint;
        CGPoint reflectionPoint = prevPoint;
        
        do {
            float A2 = point1.y - point2.y;
            float B2 = point2.x - point1.x;
            float C2 = point1.x * point2.y - point2.x * point1.y;
            
            crossPoint.x = -(C1*B2 - C2*B1)/(A1*B2 - A2*B1);
            crossPoint.y = -(A1*C2 - A2*C1)/(A1*B2 - A2*B1);
            if(CGRectContainsPoint(testField, crossPoint))
            {
                if(point1.x == point2.x)
                    reflectionPoint.x = point1.x + (point1.x - reflectionPoint.x);
                else
                    reflectionPoint.y = point1.y + (point1.y - reflectionPoint.y);
                    
                break;
            }
            
            A2 = point1.y - point3.y;
            B2 = point3.x - point1.x;
            C2 = point1.x * point3.y - point3.x * point1.y;
            
            crossPoint.x = -(C1*B2 - C2*B1)/(A1*B2 - A2*B1);
            crossPoint.y = -(A1*C2 - A2*C1)/(A1*B2 - A2*B1);
            if(CGRectContainsPoint(testField, crossPoint))
            {
                if(point1.x == point3.x)
                    reflectionPoint.x = point1.x + (point1.x - reflectionPoint.x);
                else
                    reflectionPoint.y = point1.y + (point1.y - reflectionPoint.y);
                
                break;
            }
            NSLog(@"ThrowDiceEngine: ERROR!!! No crossPoint found!");
            return path;
        } while (0);
        
        
        float distance = sqrtf(powf(crossPoint.x - currentPoint.x, 2) + powf(crossPoint.y - currentPoint.y, 2));
        float velocityAtEndpoint = velocity - distance * velocityFading;
        if(velocityAtEndpoint < 0)
        {
            float newDistance = velocity / velocityFading;
            crossPoint.x = currentPoint.x + (crossPoint.x - currentPoint.x)*newDistance/distance;
            crossPoint.y = currentPoint.y + (crossPoint.y -currentPoint.y)*newDistance/distance;
            velocityAtEndpoint = 0;
            distance = newDistance;
        }

        NSMutableDictionary *value = [[NSMutableDictionary alloc] initWithCapacity:3];
        [value setValue:[NSNumber numberWithFloat:crossPoint.x] forKey:@"x"];
        [value setValue:[NSNumber numberWithFloat:crossPoint.y] forKey:@"y"];
        [value setValue:[NSNumber numberWithFloat:MAX(0.1, distance/velocity)] forKey:@"duration"];

        [path addObject:value];
        
        velocity = velocityAtEndpoint;
        prevPoint = reflectionPoint;
        currentPoint = crossPoint;
        
    }
    
    return path;
}

@end
