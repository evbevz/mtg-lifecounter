//
//  Card.h
//  MTG LifeCounter
//
//  Created by Mac on 10.10.11.
//  Copyright (c) 2021 Evgeny Bevz. All rights reserved.
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
    float   cellWidth, cellHeight;
    float   activeRadius;
    CGPoint moveOffset; // смещение от точки нажатия на марбл до центра марбла
    
    int     lifeBase;
    
    UIImageView *marble;
    bool        marble_tracking;
    
    UIView  *marblesSurface;
    __unsafe_unretained id     parent;
    
}

- (CGPoint) getTopLeftCellCenter;
- (void)    showMarble:(UIImageView*)marbleView withValue:(int)lifeAmount;
- (void)    setLifeBase:(int)value;

@property(nonatomic, retain) UIColor    *linesColor;
@property(nonatomic, retain) UIImage    *backgroundImage;
@property(nonatomic, readwrite) float   margin;
@property(nonatomic, retain) UIFont     *font;
@property(nonatomic, retain) UIColor    *fontColor;
@property(nonatomic, retain) UIColor    *fontBorderColor;
@property(nonatomic, readonly) int      lifeBase;
@property(atomic, assign) id            parent;
@property(atomic, assign) float         activeRadius;
@property(atomic, readonly) float       cellHeight;
@property(nonatomic, retain) UIView     *marblesSurface;
@end

@protocol ViewControllerDelegate

-(void)setPlayerLifeAmount:(int)amount;
-(void)marbleMovedTo:(CGPoint)pos;
-(CGFloat)moveCardField:(CGFloat)delta;
-(CGRect)getMarbleFieldFrame;

@end
