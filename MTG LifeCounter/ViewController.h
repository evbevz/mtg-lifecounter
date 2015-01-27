//
//  ViewController.h
//  MTG LifeCounter
//
//  Created by Mac on 05.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "Card.h"

#define PLAYER_BUTTONS_CNT      3

struct PlayerData
{
    int     poison;
    int     life;
};

@interface ViewController : UIViewController
{
    float   x_scale;
    float   y_scale;
    
    int         poison_val;
    UIImageView *poison_img;
    UIButton    *poison_inc;
    UIButton    *poison_dec;
    
    UIButton    *btn20_inc;
    UIButton    *btn20_dec;
    CardView    *card;
    UIButton    *btn[PLAYER_BUTTONS_CNT];
    UIImage     *marble_img[5];
    UIImageView *marbles[PLAYER_BUTTONS_CNT];
    UIImage     *bubble;
    struct PlayerData   players[PLAYER_BUTTONS_CNT];
    int         current_player;
    bool        canChangePlayer;
    
    CGPoint     dice_throw_start;
    CGPoint     dice_throw_end;
    double      dice_throw_time;
    double      dice_previous_move_time;
    Boolean     dice_locked;
    
}

-(void)showPoison;
-(void)setPlayerLifeAmount:(int)amount;

@end
