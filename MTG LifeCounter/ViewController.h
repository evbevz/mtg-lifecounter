//
//  ViewController.h
//  MTG LifeCounter
//
//  Created by Mac on 05.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController
{
    float   x_scale;
    float   y_scale;
    
    int         poison_val;
    UIImageView *poison_img;
    UIButton    *poison_inc;
    UIButton    *poison_dec;
    
    UIButton    *btn20_inc;
    UIButton    *btn20_dec;
}

-(void)showPoison;

@end
