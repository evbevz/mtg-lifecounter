//
//  Card.h
//  MTG LifeCounter
//
//  Created by Mac on 10.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CardView : UIView
{
    UIColor *linesColor;
    UIImage *backgroundImage;
    float   margin;
    int     lifeBase;
}

@property(nonatomic, retain) UIColor *linesColor;
@property(nonatomic, retain) UIImage *backgroundImage;
@property(nonatomic, readwrite) float margin;
@property(nonatomic, readwrite) int lifeBase;

@end
