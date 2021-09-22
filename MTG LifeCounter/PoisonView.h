//
//  PoisonView.h
//  MTG LifeCounter
//
//  Created by bevz on 13.04.16.
//  Copyright (c) 2021 Evgeny Bevz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentView.h"


@interface PoisonView : UIImageView
{
    int value;
    __unsafe_unretained id     player;

}

@property(atomic, readonly) int     value;
@property(nonatomic, assign) id     player;

- (id)initWithValue:(int)value withPlayer:(id)playerDelegate;
- (void) setValue:(int)val;

@end


@protocol PoisonPlayerDelegate
-(void)setPlayerPoisonValue:(int)value;
@end
