//
//  PoisonView.m
//  MTG LifeCounter
//
//  Created by bevz on 13.04.16.
//  Copyright (c) 2021 Evgeny Bevz. All rights reserved.
//

#import "PoisonView.h"

#define POISON_PREFIX           @"Poison_"
#define POISON_MIN_VALUE        0
#define POISON_MAX_VALUE        20

@interface PoisonView()
{
    CGPoint pos0;
    Boolean touchMoved;
}

@end


@implementation PoisonView

@synthesize value;
@synthesize player;

- (id)initWithValue:(int)value withPlayer:(id)playerDelegate
{
    int val = MIN(MAX(POISON_MIN_VALUE, value), POISON_MAX_VALUE);
    self = [super initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png",POISON_PREFIX, val]]];
    self.value = val;
    self.player = playerDelegate;
    self.userInteractionEnabled = YES;
    touchMoved = NO;
    
    return self;
}

- (void) setValue:(int)val
{
    value = val;
    [self showPoison];
}

- (void) showPoison
{
    // normalize
    int val = self.value;
    val = MIN(MAX(POISON_MIN_VALUE, val),POISON_MAX_VALUE);
    self.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png", POISON_PREFIX, val]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    pos0 = [touch locationInView:self];
    touchMoved = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchMoved = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(!touchMoved)
    {
        UITouch* touch = [touches anyObject];
        CGPoint pos = [touch locationInView:self];
        if(pos.y < self.frame.size.height/2 && value < 20)
        {
            value++;
            [self showPoison];
            
            if(player)
                [player setPlayerPoisonValue:value];
        }
        
        if(pos.y > self.frame.size.height/2 && value > 0)
        {
            value--;
            [self showPoison];
            
            if(player)
                [player setPlayerPoisonValue:value];
        }
        
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self];
    if(pos.y - pos0.y > self.frame.size.height/25)
    {
        pos0 = pos;
        touchMoved = YES;
        
        if(value > 0)
        {
            value--;
            [self showPoison];
            if(player)
                [player setPlayerPoisonValue:value];
        }
        
    }
    if(pos.y - pos0.y < -self.frame.size.height/25)
    {
        pos0 = pos;
        touchMoved = YES;
        
        if(value < 20)
        {
            value++;
            [self showPoison];
        
            if(player)
                [player setPlayerPoisonValue:value];
        }
    }
    
    if(!touchMoved && fabs(pos.x - pos0.x) > self.frame.size.height/25)
    {
        // prevent change value on touch end
        touchMoved = YES;
    }
    
}

@end
