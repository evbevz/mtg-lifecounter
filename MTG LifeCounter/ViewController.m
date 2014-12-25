//
//  ViewController.m
//  MTG LifeCounter
//
//  Created by Mac on 05.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "ContentView.h"
#import <QuartzCore/CABase.h>
#import "ThrowDiceEngine.h"
#import <QuartzCore/QuartzCore.h>
#import "OpenGLView.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define CARD_ROTATE_DURATION    0.4

#define CardNumbersColor        [UIColor colorWithRed:228.0/255 green:178.0/255 blue:114.0/255 alpha:1]
#define CardNumbersBorderColor  [UIColor colorWithRed:57.0/255 green:34.0/255 blue:4.0/255 alpha:1]
#define POISON_PREFIX           @"Poison_"

#define MIN_SCALE               MIN(x_scale, y_scale)
#define MAX_SCALE               MAX(x_scale, y_scale)


@interface ViewController () {
    UIView*     glView;
        
}

- (void)selectPlayer:(int)i;

@end

@implementation ViewController

#pragma mark - regular ViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    y_scale = [UIScreen mainScreen].bounds.size.height / 1024;
	x_scale = [UIScreen mainScreen].bounds.size.width / 768;
    
    current_player = 0;
    dice_in_animation = NO;
    
    UIImageView *main = [[UIImageView alloc] initWithFrame:self.view.frame];
    main.image = [UIImage imageNamed:@"Background.png"];
    glView = self.view;
    self.view = main;
    [self.view setUserInteractionEnabled:true];
    
    
    
    //NSLog(@"Create CardView");
    card = [[CardView alloc] initWithFrame:self.view.frame];
    card.backgroundImage = [UIImage imageNamed:@"Field.png"];
    card.frame = CGRectMake(140.0 * x_scale, 110.0 * y_scale, card.backgroundImage.size.width * x_scale, card.backgroundImage.size.height * y_scale);
    card.margin = 2;
    card.font = [UIFont fontWithName:@"GaramondPremrPro-Smbd" size:70 * x_scale];
    card.linesColor = [UIColor clearColor];
    card.fontColor = CardNumbersColor;
    card.fontBorderColor = CardNumbersBorderColor;
    card.backgroundColor = [UIColor clearColor];
    card.parent = self;
    [self.view addSubview:card];
    
    float bottomBaseLine = card.frame.origin.y + card.frame.size.height + ([UIScreen mainScreen].bounds.size.height - (card.frame.origin.y + card.frame.size.height)) / 2.3;
    
    // +20/-20
    UIImageView *btn20back = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Btn20Back.png"]];
    float width = btn20back.image.size.width * MAX_SCALE;
    float height = btn20back.image.size.height * MAX_SCALE;
    btn20back.frame = CGRectMake(card.frame.origin.x + card.frame.size.width/2 - width/2, bottomBaseLine - height/2, width, height);
    [self.view addSubview:btn20back];
    
    UIImage *img = [UIImage imageNamed:@"Btn-20.png"];
	btn20_dec = [UIButton buttonWithType:UIButtonTypeCustom];
    width = img.size.width * MAX_SCALE;
    height = img.size.height * MAX_SCALE;
    btn20_dec.frame = CGRectMake(card.frame.origin.x + card.frame.size.width/2 - width - 5.0*MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
	[btn20_dec setImage:img forState:UIControlStateNormal];
    [btn20_dec addTarget:self action:@selector(counterButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn20_dec];

    img = [UIImage imageNamed:@"Btn+20.png"];
	btn20_inc = [UIButton buttonWithType:UIButtonTypeCustom];
    btn20_inc.frame = CGRectMake(card.frame.origin.x + card.frame.size.width/2 + 5.0*MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
	[btn20_inc setImage:img forState:UIControlStateNormal];
    [btn20_inc addTarget:self action:@selector(counterButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn20_inc];

    // Poison
    poison_val = 0;
    poison_img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png",POISON_PREFIX,poison_val]]];
    width = poison_img.image.size.width * MAX_SCALE;
    height = poison_img.image.size.height * MAX_SCALE;
    poison_img.frame = CGRectMake(45.0 * x_scale, card.frame.origin.y + card.frame.size.height - poison_img.image.size.height * MAX_SCALE + 10 * MAX_SCALE, width, height);
    [self.view addSubview:poison_img];
    
    UIImageView *poison_btn_back = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PoisonBtnsBack.png"]];
    width = poison_btn_back.image.size.width * MAX_SCALE;
    height = poison_btn_back.image.size.height * MAX_SCALE;
    poison_btn_back.frame = CGRectMake(27.0 * x_scale, bottomBaseLine - height/2, width, height);
    [self.view addSubview:poison_btn_back];
    
    img = [UIImage imageNamed:@"PoisonBtn+.png"];
    poison_inc = [UIButton buttonWithType:UIButtonTypeCustom];
    width = img.size.width * MAX_SCALE;
    height = img.size.height * MAX_SCALE;
    poison_inc.frame = CGRectMake(poison_btn_back.frame.origin.x + poison_btn_back.frame.size.width/2 - 2.0 * MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
    [poison_inc setImage:img forState:UIControlStateNormal];
    [poison_inc setImage:[UIImage imageNamed:@"PoisonBtn+A.png"] forState:UIControlStateHighlighted];
    [poison_inc addTarget:self action:@selector(poisonButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:poison_inc];

    img = [UIImage imageNamed:@"PoisonBtn-.png"];
    poison_dec = [UIButton buttonWithType:UIButtonTypeCustom];
    poison_dec.frame = CGRectMake(poison_btn_back.frame.origin.x + poison_btn_back.frame.size.width/2 - width + 2.0 * MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
    [poison_dec setImage:img forState:UIControlStateNormal];
    [poison_dec setImage:[UIImage imageNamed:@"PoisonBtn-A.png"] forState:UIControlStateHighlighted];
    [poison_dec addTarget:self action:@selector(poisonButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:poison_dec];

    //bubbles & marbles
    marble_img[0] = [UIImage imageNamed:@"MarbleBlue.png"];
    marble_img[1] = [UIImage imageNamed:@"MarbleGreen.png"];
    marble_img[2] = [UIImage imageNamed:@"MarbleRed.png"];
    marble_img[3] = [UIImage imageNamed:@"MarbleWhite.png"];
    marble_img[4] = [UIImage imageNamed:@"MarbleBlack.png"];
    float bubblesBase = card.frame.origin.x / 1.75;
    bubble = [UIImage imageNamed:@"Bubble.png"];
    width = bubble.size.width * MAX_SCALE;
    height = bubble.size.height * MAX_SCALE;
    float top = card.frame.origin.y ;
    for(int i = 0; i < PLAYER_BUTTONS_CNT; ++i)
    {
        // marble place
        UIImageView *marble_place = [[UIImageView alloc] initWithImage:bubble];
        marble_place.frame = CGRectMake(bubblesBase - width/2, top, width, height);
        [self.view addSubview:marble_place];
        
        // marble button        
        btn[i] = [UIButton buttonWithType:UIButtonTypeCustom];
        btn[i].frame = CGRectMake(bubblesBase - width/2, top, width, height);
        [btn[i] setImage:marble_img[i] forState:UIControlStateNormal];
        CGFloat edge_top = (marble_img[i].size.height - bubble.size.height)/2 * MAX_SCALE;
        CGFloat edge_left = (marble_img[i].size.width - bubble.size.width)/2 * MAX_SCALE;
        btn[i].imageEdgeInsets = UIEdgeInsetsMake(-edge_top,-edge_left,-edge_top,-edge_left);
        [btn[i] addTarget:self action:@selector(playerButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        //btn[i].alpha = 0.5;
        
        [self.view addSubview:btn[i]];
        
        // marble
        marbles[i] = [[UIImageView alloc] initWithImage:marble_img[i]];
        marbles[i].frame = CGRectMake(0,0,marble_img[i].size.width * MAX_SCALE, marble_img[i].size.height * MAX_SCALE);
        //marbles[i].alpha = 0.5;
        
        top += (card.frame.size.height - poison_img.frame.size.height*0.9)/PLAYER_BUTTONS_CNT;
        players[i].poison = 0;
        players[i].life = 20;
    }
    
    canChangePlayer = true;

    // Dice GL
    
    dice_size = 110.0 * MAX_SCALE;
    float margin = 30;
    dice_position = CGPointMake([UIScreen mainScreen].bounds.size.width - dice_size/2 - margin * x_scale, [UIScreen mainScreen].bounds.size.height - dice_size/2 - margin * y_scale);
    
    glView = [[OpenGLView alloc] initWithFrame:CGRectMake(dice_position.x - dice_size/2, dice_position.y - dice_size/2, dice_size, dice_size)];
    [self.view addSubview:glView];
    glView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if(interfaceOrientation == UIInterfaceOrientationPortrait)
        return YES;
    
    return NO;
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self becomeFirstResponder];
}

- (void)playerButtonTouched:(UIButton*)button
{
    if(!canChangePlayer)
        return;
    
    for (int i = 0; i < PLAYER_BUTTONS_CNT; ++i) {
        if (btn[i] == button) 
        {
            [self selectPlayer:i];
        }
    }
}

- (void)counterButtonTouched:(UIButton*)button
{
    if(button == btn20_dec && card.lifeBase >= 20)
    {
        card.lifeBase -= 20;
        players[current_player].life -= 20;
    }
    if(button == btn20_inc && card.lifeBase < 1980)
    {
        card.lifeBase += 20;
        players[current_player].life += 20;
    }
    [card setNeedsDisplay];
}

- (void)poisonButtonTouched:(UIButton*)button
{
    if(button == poison_inc && poison_val < 10)
    {
        poison_val++;
        [self showPoison];
    }
    
    if(button == poison_dec && poison_val > 0)
    {
        poison_val--;
        [self showPoison];
    }

    players[current_player].poison = poison_val;

}

- (void) showPoison
{
    poison_img.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png", POISON_PREFIX, poison_val]];
}

- (void)flipCard:(int)toPlayer
{
	NSLog(@"showCardForButton");
    
    canChangePlayer = false;
    [UIView beginAnimations:@"flipCard" context:(void*)toPlayer];
    [UIView setAnimationDuration:CARD_ROTATE_DURATION];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(flipCardAnimationDidStop:finished:context:)];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                           forView:card cache:YES];
    btn[toPlayer].alpha = 0;
    if (toPlayer != current_player) {
        btn[current_player].alpha = 1;
    }
    
    card.lifeBase = (players[toPlayer].life - 1) / 20 * 20;
    [card setNeedsDisplay];
    NSLog(@"New lifebase = %d", card.lifeBase);
    
    [UIView commitAnimations];
	
    /*
     if (_sound)
     {
     NSURL* soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Cards_turning.wav"																				 ofType:nil]];
     self.player = [[[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil] autorelease];
     [self.player play];
     }
     
     _rotateEnabled = NO;
     */
}
- (void)flipCardAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	//NSLog(@"animationDidStop");
    
	if([animationID isEqual: @"flipCard"])
    {
        canChangePlayer = true;
        
        int toPlayer = (int)context;
        btn[toPlayer].hidden = true;
        btn[toPlayer].alpha = 1;
        current_player = toPlayer;
        
        marbles[toPlayer].alpha = 0;
        [card showMarble:marbles[toPlayer] withValue:players[toPlayer].life];
        
        [UIView beginAnimations:@"showMarble" context:(void*)toPlayer];
        [UIView setAnimationDuration:CARD_ROTATE_DURATION / 2];
        [UIView setAnimationDelegate:self];
        marbles[toPlayer].alpha = 1;
        [UIView commitAnimations];
  }
}

- (void)selectPlayer:(int)i
{
    if (i != current_player) {
        btn[current_player].alpha = 0;
        btn[current_player].hidden = false;
    }
    [card showMarble:NULL withValue:1];
    [self flipCard:i];
    
    poison_val = players[i].poison;
    [self showPoison];
    
}

- (void)setPlayerLifeAmount:(int)amount
{
    players[current_player].life = amount;
}

#pragma mark - ViewController touches methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"touchBegan/ dice_in_animation: %d", (int)dice_in_animation);
    //if(dice_in_animation)
    //{
        NSLog(@"remove animation");
        [self.view.layer removeAllAnimations]; 
        dice_in_animation = false;
    //}
    
   
    UITouch* touch = [touches anyObject];
    if(CGRectContainsPoint(glView.frame, [touch locationInView:self.view]))
    {
        NSLog(@"dice touch began");
        dice_throw_start = [touch locationInView:self.view];
        dice_throw_time = CACurrentMediaTime();
        dice_locked = YES;
        
        if(dice_in_animation)
        {
            NSLog(@"remove animation");
            [self.view.layer removeAllAnimations]; 
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchCancelled");
    
    dice_locked = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchEnded");
    
    //UITouch* touch = [touches anyObject];
    //dice_throw_end = [touch locationInView:self.view];
    //dice_throw_time = CACurrentMediaTime() - dice_throw_time;
    NSLog(@"time: %f", dice_throw_time);
    dice_locked = NO;
    [self throwDice];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if(dice_locked)
    {
        UITouch* touch = [touches anyObject];
        dice_position = [touch locationInView:self.view];
        glView.frame = CGRectMake(dice_position.x - dice_size/2, dice_position.y - dice_size/2, dice_size, dice_size);
        dice_throw_time = CACurrentMediaTime() - dice_previous_move_time;
        dice_previous_move_time = CACurrentMediaTime();
        dice_throw_start = [touch previousLocationInView:self.view];
        dice_throw_end = [touch locationInView:self.view];
        NSLog(@"touchMoved, time: %g", dice_throw_time);
    }
}

-(void) motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"Shake began");
}

-(void) motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"Shake canceled");
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"Shake ended");
    dice_throw_start = glView.frame.origin;
    dice_throw_end = CGPointMake((self.view.frame.size.width - dice_size) * ((double)rand()/RAND_MAX), (self.view.frame.size.height - dice_size) * ((double)rand()/RAND_MAX));
    dice_throw_time = 0.2;
    
    [self throwDice];
}

-(void) throwDice
{
    
    ThrowDiceEngine *engine = [ThrowDiceEngine alloc];
    engine.field = CGRectMake(self.view.frame.origin.x + dice_size/2, self.view.frame.origin.y + dice_size/2, self.view.frame.size.width - dice_size, self.view.frame.size.height - dice_size);
    engine.startPoint = dice_throw_start;
    engine.endPoint = dice_throw_end;
    engine.initialVelocity = MIN(400, sqrtf(powf(dice_throw_end.x - dice_throw_start.x, 2) + powf(dice_throw_end.y - dice_throw_start.y, 2))/dice_throw_time);
    engine.velocityFading = 0.5;
    
    // end point must be inside field
    if(engine.endPoint.x < engine.field.origin.x)
        engine.endPoint = CGPointMake(engine.field.origin.x, engine.endPoint.y);
    if(engine.endPoint.x > engine.field.origin.x + engine.field.size.width)
        engine.endPoint = CGPointMake(engine.field.origin.x + engine.field.size.width, engine.endPoint.y); 
    if(engine.endPoint.y < engine.field.origin.y)
        engine.endPoint = CGPointMake(engine.endPoint.x, engine.field.origin.y);
    if(engine.endPoint.y > engine.field.origin.y + engine.field.size.height)
        engine.endPoint = CGPointMake(engine.endPoint.x, engine.field.origin.y + engine.field.size.height); 
   
    
    NSLog(@"Start point: [%f,%f] \t End point: [%f,%f]", dice_throw_start.x, dice_throw_start.y, dice_throw_end.x, dice_throw_end.y);
    
    NSMutableArray *path = [engine GetPath];
    
    NSLog(@"Init velocity: %f. \tPath objects: %d", engine.initialVelocity, [path count]);
    
    //for (NSMutableDictionary* point in path) {
    //    NSLog(@"path: [%f, %f], %f sec", ((NSNumber*)[point valueForKey:@"x"]).floatValue, ((NSNumber*)[point valueForKey:@"y"]).floatValue, ((NSNumber*)[point valueForKey:@"duration"]).floatValue);
    //}

    if(path && [path count])
    {
        NSMutableDictionary *point = [path objectAtIndex:0];
        [path removeObject:point];
        
        NSLog(@"path: [%f, %f], %f sec", ((NSNumber*)[point valueForKey:@"x"]).floatValue, ((NSNumber*)[point valueForKey:@"y"]).floatValue, ((NSNumber*)[point valueForKey:@"duration"]).floatValue);
        
        [UIView beginAnimations:@"ThrowDice" context:(__bridge_retained void*)path];
        [UIView setAnimationDuration:MIN(2.0, (double)((NSNumber*)[point valueForKey:@"duration"]).floatValue)];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [UIView setAnimationCurve:([path count] > 0 ? UIViewAnimationCurveLinear : UIViewAnimationCurveEaseOut)];
        glView.frame = CGRectMake(((NSNumber*)[point valueForKey:@"x"]).floatValue - dice_size/2,((NSNumber*)[point valueForKey:@"y"]).floatValue - dice_size/2, dice_size, dice_size);
        dice_in_animation = YES;
        [UIView commitAnimations];
    }
	
    /*
     if (_sound)
     {
     NSURL* soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Cards_turning.wav"																				 ofType:nil]];
     self.player = [[[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil] autorelease];
     [self.player play];
     }
     
     _rotateEnabled = NO;
     */

}


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	NSLog(@"animationDidStop");
	if([animationID isEqual: @"ThrowDice"])
    {
        NSMutableArray *path = (__bridge_transfer NSMutableArray*)context;
        
        if([path count] == 0)
        {
            dice_in_animation = NO;
            return;
        }
        
        NSMutableDictionary *point = [path objectAtIndex:0];
        [path removeObject:point];
        
        NSLog(@"path: [%f, %f], %f sec", ((NSNumber*)[point valueForKey:@"x"]).floatValue, ((NSNumber*)[point valueForKey:@"y"]).floatValue, ((NSNumber*)[point valueForKey:@"duration"]).floatValue);
 
        [UIView beginAnimations:@"ThrowDice" context:(__bridge_retained void*)path];
        [UIView setAnimationDuration:MIN(2.0, (double)((NSNumber*)[point valueForKey:@"duration"]).floatValue)];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [UIView setAnimationCurve:([path count] > 0 ? UIViewAnimationCurveLinear : UIViewAnimationCurveEaseOut)];
        glView.frame = CGRectMake(((NSNumber*)[point valueForKey:@"x"]).floatValue - dice_size/2,((NSNumber*)[point valueForKey:@"y"]).floatValue - dice_size/2, dice_size, dice_size);
        [UIView commitAnimations];
        
    }
}



/*
- (void)update
{
    NSLog(@"update");
    float aspect = fabsf(glView.bounds.size.width / glView.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    //self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -3.3f);
    //baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix;
    //modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    //modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    //modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    //self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotation += self.timeSinceLastUpdate * 1.5f;
    
    [glView setNeedsDisplay];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //NSLog(@"drawRect");
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    //[self.effect prepareToDraw];
    
    //glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
}
*/



@end
