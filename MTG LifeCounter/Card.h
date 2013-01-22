//
//  Card.h
//  MTG LifeCounter
//
//  Created by Mac on 10.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentView.h"

@interface CardView : ContentView
{
    UIColor *linesColor;
    UIColor *fontColor;
    UIColor *fontBorderColor;
    UIImage *backgroundImage;
    float   margin;
    UIFont  *font;
    
    int     lifeBase;

    float   marble_x;
    float   marble_y;
    
    UIImageView *marble;
    bool        marble_tracking;
    CGPoint     marble_position;
    
    __unsafe_unretained id     parent;
    
}

- (CGPoint) getTopLeftCellCenter;
- (void)    showMarble:(UIImageView*)marbleView withValue:(int)lifeAmount;

@property(nonatomic, retain) UIColor    *linesColor;
@property(nonatomic, retain) UIImage    *backgroundImage;
@property(nonatomic, readwrite) float   margin;
@property(nonatomic, retain) UIFont     *font;
@property(nonatomic, retain) UIColor    *fontColor;
@property(nonatomic, retain) UIColor    *fontBorderColor;
@property(nonatomic, readwrite) int lifeBase;
@property(nonatomic, assign) id     parent;

@end

@protocol ViewControllerDelegate

-(void)setPlayerLifeAmount:(int)amount;

@end