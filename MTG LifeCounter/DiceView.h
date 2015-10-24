//
//  DiceView.h
//  MTG LifeCounter
//
//  Created by bevz on 23/10/15.
//
//

#import <GLKit/GLKit.h>

@interface DiceView : GLKView

-(void) throwDice:(float)v0 withX0:(float)x0 withY0:(float)y0;
-(void) moveDice:(CGSize)delta;
-(BOOL) diceTouched:(CGPoint)pos;
-(void) setDiceDefaultPlace:(CGPoint)pos;
-(void) moveDiceToDefaultPlace;

@end
