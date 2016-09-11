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
#import "PoisonView.h"

#define PLAYER_BUTTONS_CNT      2

struct PlayerData
{
    int     poison;
    int     life;
    int     cardLifeBase;
    CGFloat cardOriginY;
};

@interface ViewController : UIViewController<PoisonPlayerDelegate>
{
    float   x_scale;
    float   y_scale;
    
    PoisonView  *poison_img;
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
    
}

-(void)showPoison;
-(void)setPlayerLifeAmount:(int)amount;
-(void)marbleMovedTo:(CGPoint)pos;
-(CGFloat)moveCardField:(CGFloat)delta;
-(CGRect)getMarbleFieldFrame;

@end
