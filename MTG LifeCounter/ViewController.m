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
#define SHOW_20_DURATION        0.4

#define CardNumbersColor        [UIColor colorWithRed:228.0/255 green:178.0/255 blue:114.0/255 alpha:1]
#define CardNumbersBorderColor  [UIColor colorWithRed:57.0/255 green:34.0/255 blue:4.0/255 alpha:1]
#define POISON_PREFIX           @"Poison_"

#define MIN_SCALE               MIN(x_scale, y_scale)
#define MAX_SCALE               MAX(x_scale, y_scale)

#define DICE_AREA_SIZE            60
#define DICE_AREA_X_OFFSET        50

#define CARD_LIFE_BASE_X_OFFSET   10

@interface ViewController () {
    DiceView*     glView;
    bool          playerIsSelected;
    UIImageView   *btns20;
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
    main = [[UIImageView alloc] initWithFrame:frame];
    main.image = [UIImage imageNamed:@"Background.png"];
    [self.view addSubview:main];
    
    
    // Card
    card = [[CardView alloc] initWithFrame:frame];
    card.backgroundImage = [UIImage imageNamed:@"Field.png"];
    card.frame = CGRectMake(140.0 * x_scale, 110.0 * y_scale + main.frame.origin.y, card.backgroundImage.size.width * x_scale, card.backgroundImage.size.height * y_scale);
    card.margin = 2;
    card.font = [UIFont fontWithName:@"GaramondPremrPro-Smbd" size:80 * x_scale];
    card.linesColor = [UIColor clearColor];
    card.fontColor = CardNumbersColor;
    card.fontBorderColor = CardNumbersBorderColor;
    card.backgroundColor = [UIColor clearColor];
    card.parent = self;
    [self.view addSubview:card];
    
    bottomBaseLine = card.frame.origin.y + card.frame.size.height + (frame.size.height - (card.frame.origin.y - frame.origin.y + card.frame.size.height)) / 2.3;

    // Poison
    poison_val = 0;
    poison_img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png",POISON_PREFIX,poison_val]]];
    float width = poison_img.image.size.width * MAX_SCALE;
    float height = poison_img.image.size.height * MAX_SCALE;
    poison_img.frame = CGRectMake(45.0 * x_scale, card.frame.origin.y + card.frame.size.height - poison_img.image.size.height * MAX_SCALE + 10 * MAX_SCALE, width, height);
    [self.view addSubview:poison_img];
    poison_img.userInteractionEnabled = YES;
    UITapGestureRecognizer *poisonTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(poisonButtonTouched:)];
    [poison_img addGestureRecognizer:poisonTapGesture];

    
    // +20/-20
    int lblHeight = frame.origin.y + frame.size.height - bottomBaseLine;
    UILabel *baseCardAmnt = [[UILabel alloc] initWithFrame:CGRectMake(CARD_LIFE_BASE_X_OFFSET, bottomBaseLine - lblHeight/2, frame.size.width/4, lblHeight)];
    baseCardAmnt.backgroundColor = [UIColor clearColor];
    baseCardAmnt.textColor = CardNumbersBorderColor;
    baseCardAmnt.text = @"+20/-20";
    baseCardAmnt.userInteractionEnabled = YES;
    baseCardAmnt.adjustsFontSizeToFitWidth = YES;
    UITapGestureRecognizer *totalAmntTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(baseCardAmntTap:)];
    [baseCardAmnt addGestureRecognizer:totalAmntTapGesture];
    baseCardAmnt.font = [UIFont fontWithName:@"GaramondPremrPro-Smbd" size:70 * x_scale];
    [self.view addSubview:baseCardAmnt];
    NSLog(@"Label frame: %@", NSStringFromCGRect(baseCardAmnt.frame));
    
    // Dice default place area
    UIButton *dicePosArea = [UIButton buttonWithType:UIButtonTypeCustom];
    [dicePosArea setImage:[UIImage imageNamed:@"dice-place.png"] forState:UIControlStateNormal];
    dicePosArea.frame = CGRectMake(frame.size.width - DICE_AREA_X_OFFSET * MAX_SCALE - DICE_AREA_SIZE * MAX_SCALE, bottomBaseLine - DICE_AREA_SIZE/2 * MAX_SCALE, DICE_AREA_SIZE * MAX_SCALE, DICE_AREA_SIZE * MAX_SCALE);
    [dicePosArea addTarget:self action:@selector(diceAreaTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dicePosArea];
    
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
    glView = [[DiceView alloc] initWithFrame:frame];
    [self.view addSubview:glView];
    glView.backgroundColor = [UIColor clearColor];
    [glView setDiceDefaultPlace:CGPointMake(dicePosArea.frame.origin.x + dicePosArea.frame.size.width/2, dicePosArea.frame.origin.y + dicePosArea.frame.size.height/2)];
    [self updateMarbleCoords];
    
    // +20/-20 buttons view
    btns20 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Btn20Back.png"]];
    width = btns20.image.size.width * MAX_SCALE;
    height = btns20.image.size.height * MAX_SCALE;
    btns20.frame = CGRectMake(0, frame.size.height, width, height);
    [self.view addSubview:btns20];
    
    UIImage *img = [UIImage imageNamed:@"Btn-20.png"];
    btn20_dec = [UIButton buttonWithType:UIButtonTypeCustom];
    width = img.size.width * MAX_SCALE;
    height = img.size.height * MAX_SCALE;
    btn20_dec.frame = CGRectMake(btns20.frame.size.width/2 - width - 5.0*MAX_SCALE, btns20.frame.size.height/2 - height/2 + 1, width, height);
    [btn20_dec setImage:img forState:UIControlStateNormal];
    [btn20_dec addTarget:self action:@selector(counterButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [btns20 addSubview:btn20_dec];
    
    img = [UIImage imageNamed:@"Btn+20.png"];
    btn20_inc = [UIButton buttonWithType:UIButtonTypeCustom];
    btn20_inc.frame = CGRectMake(btns20.frame.size.width/2 + 5.0*MAX_SCALE, btns20.frame.size.height/2 - height/2 + 1, width, height);
    [btn20_inc setImage:img forState:UIControlStateNormal];
    [btn20_inc addTarget:self action:@selector(counterButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [btns20 addSubview:btn20_inc];
    btns20.userInteractionEnabled = YES;
    btns20.alpha = 0;

    // init player
    [self selectPlayer:0];
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
        }
    }
}

- (void)counterButtonTouched:(UIButton*)button
{
    if(!canChangePlayer)
        return;

    int increment = (button == btn20_dec ? -1 : 1);
    if(button == btn20_dec && card.lifeBase >= 20)
    {
        [card setLifeBase:(card.lifeBase - 20) withAnimation:YES];
        players[current_player].life -= 20;
    }
    if(button == btn20_inc && card.lifeBase < 1980)
    {
        [card setLifeBase:(card.lifeBase + 20) withAnimation:YES];
        players[current_player].life += 20;
    }
    [self show20:false withDirection:increment];
}

- (void)poisonButtonTouched:(UITapGestureRecognizer*)gesture
{
    UIView *poison = gesture.view;
    CGPoint pos = [gesture locationInView:poison];
    if(pos.y < poison.frame.size.height/2 && poison_val < 10)
    {
        poison_val++;
        [self showPoison];
    }
    
    if(pos.y > poison.frame.size.height/2 && poison_val > 0)
    {
        poison_val--;
        [self showPoison];
    }

    players[current_player].poison = poison_val;

}

- (void)diceAreaTouched:(UIButton*)button
{
    [glView moveDiceToDefaultPlace];
    [glView throwDice:1 withX0:0 withY0:0];
}

- (void)baseCardAmntTap:(UITapGestureRecognizer*)recognizer
{
    if(btns20.alpha == 0)
        [self show20:true withDirection:1];
    else
        [self show20:false withDirection:-1];
}

#pragma mark - Display events

- (void) showPoison
{
    poison_img.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png", POISON_PREFIX, poison_val]];
}

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
    
    [card setLifeBase:((players[toPlayer].life - 1) / 20 * 20) withAnimation:NO];
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

- (void)show20:(Boolean)show withDirection:(int)direction
{
    canChangePlayer = false;

    if(show)
    {
        btns20.frame = CGRectMake(card.frame.origin.x + card.frame.size.width / 2 - btns20.frame.size.width/2,
                                  card.frame.origin.y + card.frame.size.height - btns20.frame.size.height*1.1,
                                  btns20.frame.size.width, btns20.frame.size.height);
    }
    [UIView beginAnimations:@"show20" context:(void*)NULL];
    [UIView setAnimationDuration:SHOW_20_DURATION];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(show20DidStop:finished:context:)];
    [UIView setAnimationTransition:(direction < 0 ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft) forView:btns20 cache:YES];
    
    btns20.alpha = (show ? 1: 0);

    [UIView commitAnimations];
}

- (void)show20DidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if([animationID isEqual: @"show20"])
    {
        canChangePlayer = true;
        if(btns20.alpha == 0)
            btns20.frame = CGRectMake(card.frame.origin.x + card.frame.size.width / 2 - btns20.frame.size.width/2,
                                  self.view.frame.size.height, btns20.frame.size.width, btns20.frame.size.height);
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
    playerIsSelected = true;
}

- (void)setPlayerLifeAmount:(int)amount
{
    players[current_player].life = amount;
}

- (void)updateMarbleCoords
{
    float radius = btn[0].frame.size.width / 2 * 1.3;
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
    float radius = btn[0].frame.size.width / 2 * 1.3;
    CGPoint coords[PLAYER_BUTTONS_CNT];
    for (unsigned int i = 0; i < PLAYER_BUTTONS_CNT; ++i) {
        if(!playerIsSelected || current_player != i)
            coords[i] = CGPointMake(btn[i].frame.origin.x + btn[i].frame.size.width / 2, btn[i].frame.origin.y + btn[i].frame.size.height / 2);
        else
            coords[i] = CGPointMake(card.frame.origin.x + pos.x, card.frame.origin.y + pos.y);
    }
    [glView setMarblesCoords:coords andCount:PLAYER_BUTTONS_CNT withRadius:radius];
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
