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
#import "DiceView.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define CARD_ROTATE_DURATION    0.4

#define CardNumbersColor        [UIColor colorWithRed:228.0/255 green:178.0/255 blue:114.0/255 alpha:1]
#define CardNumbersBorderColor  [UIColor colorWithRed:57.0/255 green:34.0/255 blue:4.0/255 alpha:1]

#define MIN_SCALE               MIN(x_scale, y_scale)
#define MAX_SCALE               MAX(x_scale, y_scale)

#define DICE_AREA_SIZE            80
#define DICE_AREA_X_OFFSET        60

#define MARBLE_BUTTONS_X_OFFSET   10

#define MARBLE_SCALE              1.5

#define CARD_NATIVE_OFFSET_X    144
#define CARD_NATIVE_OFFSET_Y    108
#define CARD_NATIVE_WIDTH       560
#define CARD_NATIVE_HEIGHT      721
#define CARD_NATIVE_BKHEIGHT    1438


@interface ViewController () {
    DiceView*     glView;
    bool          playerIsSelected;
    UIImageView   *main;
    float         bottomBaseLine;
}

- (void)selectPlayer:(int)i;

@end

@implementation ViewController

#pragma mark - regular ViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect frame = [UIScreen mainScreen].bounds;
    //NSLog(@"Main Frame: %g x %g", frame.size.width, frame.size.height);
    if(frame.size.height/frame.size.width > 480.0/320.0)
    {
        frame.size.height = frame.size.width * 480.0 / 320.0;
        frame.origin.y = ([UIScreen mainScreen].bounds.size.height - frame.size.height)/2;
    }
    y_scale = frame.size.height / 1024;
	x_scale = frame.size.width / 768;
    
    current_player = 0;
    playerIsSelected = false;
    
    // Black field
    UIImageView *blackField = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.view = blackField;
    [self.view setUserInteractionEnabled:true];
    
   
    // Card 
    card = [[CardView alloc] initWithFrame:frame];
    card.backgroundImage = [UIImage imageNamed:@"Field.png"];
    card.frame = CGRectMake(CARD_NATIVE_OFFSET_X * x_scale, CARD_NATIVE_OFFSET_Y * y_scale + frame.origin.y - (CARD_NATIVE_BKHEIGHT - CARD_NATIVE_HEIGHT)*y_scale, CARD_NATIVE_WIDTH * x_scale, CARD_NATIVE_BKHEIGHT * y_scale);
    card.margin = 0;
    card.font = [UIFont fontWithName:@"GaramondPremrPro-Smbd" size:80 * x_scale];
    card.linesColor = [UIColor clearColor];
    card.fontColor = CardNumbersColor;
    card.fontBorderColor = CardNumbersBorderColor;
    card.backgroundColor = [UIColor clearColor];
    card.parent = self;
    [self.view addSubview:card];
    float card_height = CARD_NATIVE_HEIGHT * y_scale;
    
    // Background with hole
    main = [[UIImageView alloc] initWithFrame:frame];
    main.image = [UIImage imageNamed:@"BackGrHole.png"];
    [self.view addSubview:main];
    card.marblesSurface = main;
  
    float cardTopLine = CARD_NATIVE_OFFSET_Y * y_scale + main.frame.origin.y;
    bottomBaseLine = cardTopLine + card_height + (frame.size.height - (cardTopLine - frame.origin.y + card_height)) / 2.3;

    // Poison
    poison_img = [[PoisonView alloc] initWithValue:0 withPlayer:self];
    float width = poison_img.image.size.width * MAX_SCALE;
    float height = poison_img.image.size.height * MAX_SCALE;
    poison_img.frame = CGRectMake(25.0 * x_scale, cardTopLine + card_height - poison_img.image.size.height * MAX_SCALE + 10 * MAX_SCALE, width, height);
    [self.view addSubview:poison_img];

    
    // Dice default place area
    UIButton *dicePosArea = [UIButton buttonWithType:UIButtonTypeCustom];
    [dicePosArea setImage:[UIImage imageNamed:@"dice-place.png"] forState:UIControlStateNormal];
    dicePosArea.frame = CGRectMake(frame.size.width - DICE_AREA_X_OFFSET * MAX_SCALE - DICE_AREA_SIZE * MAX_SCALE, bottomBaseLine - DICE_AREA_SIZE/2 * MAX_SCALE, DICE_AREA_SIZE * MAX_SCALE, DICE_AREA_SIZE * MAX_SCALE);
    [dicePosArea addTarget:self action:@selector(diceAreaTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dicePosArea];
    
    //bubbles & marbles
    marble_img[0] = [UIImage imageNamed:@"MarbleBlue.png"];
    marble_img[1] = [UIImage imageNamed:@"MarbleRed.png"];
    marble_img[2] = [UIImage imageNamed:@"MarbleGreen.png"];
    marble_img[3] = [UIImage imageNamed:@"MarbleWhite.png"];
    marble_img[4] = [UIImage imageNamed:@"MarbleBlack.png"];
    float bubblesAreaWidth = frame.size.width / 2 - MARBLE_BUTTONS_X_OFFSET;
    bubble = [UIImage imageNamed:@"Bubble.png"];
    width = bubble.size.width * MAX_SCALE * MARBLE_SCALE;
    height = bubble.size.height * MAX_SCALE * MARBLE_SCALE;
    for(int i = 0; i < PLAYER_BUTTONS_CNT; ++i)
    {
        players[i].poison = 0;
        players[i].life = 20;
        players[i].cardLifeBase = 0;
        players[i].cardOriginY = card.frame.origin.y;

        // marble
        marbles[i] = [[UIImageView alloc] initWithImage:marble_img[i]];
        marbles[i].frame = CGRectMake(0,0,marble_img[i].size.width * MAX_SCALE * MARBLE_SCALE, marble_img[i].size.height * MAX_SCALE * MARBLE_SCALE);
        [marbles[i] addSubview:[self getMarbleLabel]];
        
        // marble place
        UIImageView *marble_place = [[UIImageView alloc] initWithImage:bubble];
        marble_place.frame = CGRectMake(MARBLE_BUTTONS_X_OFFSET + bubblesAreaWidth/PLAYER_BUTTONS_CNT/2*(2*i + 1) - width/2, bottomBaseLine - height/2, width, height);
        [self.view addSubview:marble_place];
        
        // marble button        
        btn[i] = [UIButton buttonWithType:UIButtonTypeCustom];
        btn[i].frame = CGRectMake(marble_place.frame.origin.x, marble_place.frame.origin.y, width, height);
        [btn[i] setImage:marble_img[i] forState:UIControlStateNormal];
        btn[i].contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        btn[i].contentHorizontalAlignment = UIControlContentVerticalAlignmentFill;
        CGFloat edge_top = (marbles[i].frame.size.height - btn[i].frame.size.height)/2;
        CGFloat edge_left = (marbles[i].frame.size.width - btn[i].frame.size.width)/2;
        btn[i].imageEdgeInsets = UIEdgeInsetsMake(-edge_top,-edge_left,-edge_top,-edge_left);
        [btn[i] addTarget:self action:@selector(playerButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *btnLabel = [self getMarbleLabel];
        btnLabel.text = [NSString stringWithFormat:@"%d", players[i].life];
        float verticalShift = [[[UIDevice currentDevice] systemVersion] hasPrefix:@"6.1"] ? 10*MAX_SCALE : 0;
        btnLabel.frame = CGRectMake(0,verticalShift,btn[i].frame.size.width, btn[i].frame.size.height);
        [btn[i] addSubview:btnLabel];
        [self.view addSubview:btn[i]];
               
    }
    card.activeRadius = btn[0].frame.size.width / 2 * 1.5;
    
    canChangePlayer = true;
    
    // Dice GL
    glView = [[DiceView alloc] initWithFrame:frame];
    [self.view addSubview:glView];
    glView.backgroundColor = [UIColor clearColor];
    [glView setDiceDefaultPlace:CGPointMake(dicePosArea.frame.origin.x + dicePosArea.frame.size.width/2, dicePosArea.frame.origin.y + dicePosArea.frame.size.height/2)];
    [self updateMarbleCoords];
    
    // init player
    [self selectPlayer:0];
}

- (UILabel*)getMarbleLabel
{
    UIFont *lblFont = [UIFont fontWithName:@"GaramondPremrPro-Smbd" size:80 * x_scale * 1.3];
    NSString *str = [[NSString alloc] initWithUTF8String:"200"];
    CGSize txtSize = [str sizeWithFont:lblFont];
    float verticalShift = [[[UIDevice currentDevice] systemVersion] hasPrefix:@"6.1"] ? 10*MAX_SCALE : 0;
    UILabel *marbleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, verticalShift + (marbles[0].frame.size.height - txtSize.height)/2, marbles[0].frame.size.width, txtSize.height)];
    marbleLabel.font = lblFont;
    marbleLabel.text = @"";
    marbleLabel.textAlignment = NSTextAlignmentCenter;
    marbleLabel.backgroundColor = [UIColor clearColor];
    marbleLabel.alpha = 0.5;
    marbleLabel.textColor = CardNumbersBorderColor;
    return marbleLabel;
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

#pragma mark -Touches

- (void)playerButtonTouched:(UIButton*)button
{
    if(!canChangePlayer)
        return;
    
    for (int i = 0; i < PLAYER_BUTTONS_CNT; ++i) {
        if (btn[i] == button) 
        {
            [self diceAreaTouched:button];
            [self selectPlayer:i];
            break;
        }
    }
}

- (void)diceAreaTouched:(UIButton*)button
{
    [glView moveDiceToDefaultPlace];
    [glView throwDice:1 withX0:0 withY0:0];
}

-(CGFloat)moveCardField:(CGFloat)delta
{
    CGFloat newOriginY = card.frame.origin.y + delta;
    CGFloat actualMoved = delta;
    
    // check and shift card values
    if(newOriginY > CARD_NATIVE_OFFSET_Y * y_scale + main.frame.origin.y)
    {
        [card setLifeBase:(card.lifeBase + 20) withAnimation:NO];
        newOriginY -= card.cellHeight * 5;
    }
    else if(newOriginY < CARD_NATIVE_OFFSET_Y * y_scale + main.frame.origin.y - (CARD_NATIVE_BKHEIGHT - CARD_NATIVE_HEIGHT)*y_scale)
    {
        if(card.lifeBase > 0)
        {
            [card setLifeBase:(card.lifeBase - 20) withAnimation:NO];
            newOriginY += card.cellHeight * 5;
        }
        else
        {
            newOriginY = CARD_NATIVE_OFFSET_Y * y_scale + main.frame.origin.y - (CARD_NATIVE_BKHEIGHT - CARD_NATIVE_HEIGHT)*y_scale;
            actualMoved = newOriginY - card.frame.origin.y;
        }
    }

    card.frame = CGRectMake(card.frame.origin.x,
                            newOriginY,
                            card.frame.size.width,
                            card.frame.size.height);
    
    players[current_player].cardOriginY = newOriginY;
    players[current_player].cardLifeBase = card.lifeBase;
    
    return actualMoved;
}

-(CGRect)getMarbleFieldFrame
{
    return CGRectMake(CARD_NATIVE_OFFSET_X * x_scale, CARD_NATIVE_OFFSET_Y * y_scale, CARD_NATIVE_WIDTH * x_scale, CARD_NATIVE_HEIGHT * y_scale);
}

#pragma mark - Display events

- (void)flipCard:(int)toPlayer
{
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
    
    [card setLifeBase:players[toPlayer].cardLifeBase withAnimation:NO];
    card.frame = CGRectMake(card.frame.origin.x, players[toPlayer].cardOriginY, card.frame.size.width, card.frame.size.height);
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
	if([animationID isEqual: @"flipCard"])
    {
        canChangePlayer = true;
        
        int toPlayer = (int)context;
        btn[toPlayer].hidden = true;
        btn[toPlayer].alpha = 1;
        current_player = toPlayer;
        [self  updateMarbleLabel];
        
        marbles[toPlayer].alpha = 0;
        [card showMarble:marbles[toPlayer] withValue:players[toPlayer].life];
        
        [UIView beginAnimations:@"showMarble" context:(void*)toPlayer];
        [UIView setAnimationDuration:CARD_ROTATE_DURATION / 2];
        [UIView setAnimationDelegate:self];
        marbles[toPlayer].alpha = 1;
        [UIView commitAnimations];
    }
    [self updateMarbleCoords];

}

- (void)selectPlayer:(int)i
{
    if (i != current_player) {
        btn[current_player].alpha = 0;
        btn[current_player].hidden = false;
    }
    [card showMarble:NULL withValue:1];
    [self flipCard:i];
    
    [poison_img setValue:players[i].poison];
    playerIsSelected = true;
}

- (void)setPlayerLifeAmount:(int)amount
{
    if(players[current_player].life != amount)
    {
        players[current_player].life = amount;
        [self updateMarbleLabel];
        UILabel *btnLabel = btn[current_player].subviews[1];
        btnLabel.text = [NSString stringWithFormat:@"%d", amount];
    }    
}

- (void)updateMarbleLabel
{
    if(marbles[current_player].subviews.count)
    {
        UILabel *marbleLabel = marbles[current_player].subviews[0];
        [UIView transitionWithView:marbleLabel
                          duration:1.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            marbleLabel.text = [NSString stringWithFormat:@"%d", players[current_player].life];
                        } completion:nil];
    }
}

// TODO: коорлинаты подправить
- (void)updateMarbleCoords
{
    float radius = btn[0].frame.size.width / 2 * 1.1;
    CGPoint coords[PLAYER_BUTTONS_CNT];
    for (unsigned int i = 0; i < PLAYER_BUTTONS_CNT; ++i) {
        if(!playerIsSelected || current_player != i)
            coords[i] = CGPointMake(btn[i].frame.origin.x + btn[i].frame.size.width / 2, btn[i].frame.origin.y + btn[i].frame.size.height / 2);
        else
            coords[i] = CGPointMake(marbles[i].frame.origin.x + marbles[i].frame.size.width / 2 + card.frame.origin.x, marbles[i].frame.origin.y + marbles[i].frame.size.height / 2 + card.frame.origin.y);
    }
    [glView setMarblesCoords:coords andCount:PLAYER_BUTTONS_CNT withRadius:radius];
}

- (void)marbleMovedTo:(CGPoint)pos
{
    float radius = btn[0].frame.size.width / 2 * 1.1;
    CGPoint coords[PLAYER_BUTTONS_CNT];
    for (unsigned int i = 0; i < PLAYER_BUTTONS_CNT; ++i) {
        if(!playerIsSelected || current_player != i)
            coords[i] = CGPointMake(btn[i].frame.origin.x + btn[i].frame.size.width / 2, btn[i].frame.origin.y + btn[i].frame.size.height / 2);
        else
            coords[i] = CGPointMake(card.frame.origin.x + pos.x, card.frame.origin.y + pos.y);
    }
    [glView setMarblesCoords:coords andCount:PLAYER_BUTTONS_CNT withRadius:radius];
}

-(void)setPlayerPoisonValue:(int)value
{
    players[current_player].poison = value;
}

#pragma mark - ViewController motion methods


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
    //dice_throw_start = glView.frame.origin;
    //dice_throw_end = CGPointMake((self.view.frame.size.width - dice_size) * ((double)rand()/RAND_MAX), (self.view.frame.size.height - dice_size) * ((double)rand()/RAND_MAX));
    //dice_throw_time = 0.2;
    
    //[glView throwDice:10 withX0:(dice_throw_end.x-dice_throw_start.x) withY0:(dice_throw_start.y-dice_throw_end.y)];
}

@end
