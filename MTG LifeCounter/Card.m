//
//  Card.m
//  MTG LifeCounter
//
//  Created by Mac on 10.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Card.h"

#define CHANGE_LABELS_DURATION  0.3
#define ROWS    10
#define COLS    4
#define CELLS   ROWS*COLS

typedef enum LabelsAnimationDirection_ {HideLabels, ShowLabels} LabelsAnimationDirection;

@interface CardView() 
{
    CGFloat         animationDx;
    CGFloat         animationDy;
    CGFloat         duration;
    CFTimeInterval  animationStartTime;
    CADisplayLink*  displayLink;
    
    int             labelsLifeBase;
    float           labelsAlpha;
    
    LabelsAnimationDirection    direction;
}

-(void)drawLabels:(CGRect)rect :(CGContextRef)context;
-(CGPoint)cropMarblePos:(CGPoint) pos;

@end


@implementation CardView

@synthesize linesColor;
@synthesize backgroundImage;
@synthesize margin;
@synthesize font;
@synthesize lifeBase;
@synthesize fontColor;
@synthesize fontBorderColor;
@synthesize parent;
@synthesize activeRadius;
@synthesize cellHeight;
@synthesize marblesSurface;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        margin = 0;
        lifeBase = 0;
        linesColor = [UIColor blackColor];
        fontColor = [UIColor blackColor];
        font = [UIFont systemFontOfSize:20.0];
        marble_tracking = false;
        self.delegate = self;
        parent = nil;
        labelsAlpha = 1;
        cellWidth = (frame.size.width - 2*margin) / COLS;
        cellHeight = (frame.size.height - 2*margin) / ROWS;
    }
    

    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if(parent == nil || marblesSurface == nil)
        return nil;
    
    return CGRectContainsPoint([self convertRect:[parent getMarbleFieldFrame] fromView:marblesSurface], point) ? self : nil;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSLog(@"CardView:drawRect");
    
    cellWidth = (rect.size.width - 2*margin) / COLS;
    cellHeight = (rect.size.height - 2*margin) / ROWS;
    //activeRadius = MIN(cellHeight, cellWidth) / 2 * 0.8;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetStrokeColorWithColor(context, linesColor.CGColor);
    //CGContextSetFillColorWithColor(context, linesColor.CGColor);
   //CGContextClearRect(context, rect);
    
    if(backgroundImage)
        [backgroundImage drawInRect:rect];
    
    [self drawLabels:rect:context];
}


- (void)drawLabels:(CGRect)rect :(CGContextRef)context
{
    float y_offset = 1;
    float x_offset = 1;
    
    y_offset = 0.85;
    CGContextSelectFont(context, font.fontName.UTF8String, font.lineHeight, kCGEncodingMacRoman);
    if(labelsLifeBase >= 80)
    {
        y_offset = 0.8;
        CGContextSelectFont(context, font.fontName.UTF8String, font.lineHeight * 0.8, kCGEncodingMacRoman);
    }
    if(labelsLifeBase >= 980)
    {
        y_offset = 0.8;
        CGContextSelectFont(context, font.fontName.UTF8String, font.lineHeight * 0.7, kCGEncodingMacRoman);
    }
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetTextMatrix(context, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
    CGColorRef fillColor = CGColorCreateCopyWithAlpha(fontColor.CGColor, labelsAlpha);
    CGContextSetFillColorWithColor(context, fillColor);
    CGContextSetStrokeColorWithColor(context,fontBorderColor.CGColor);
    
    char txt[5];
    for(int life = labelsLifeBase + CELLS; life > labelsLifeBase; --life)
    {
        sprintf(txt, "%d", life);
        
        float cellWidth = (rect.size.width - 2*margin)/COLS;
        float cellHeight = (rect.size.height - 2*margin)/ROWS;
        
        int col = (labelsLifeBase + CELLS - life) % COLS;
        int row = (labelsLifeBase + CELLS - life) / COLS;
        //NSLog(@"col = %d \t row = %d", col, row);
        
        NSString *str = [[NSString alloc] initWithUTF8String:txt];
        CGSize txtSize = [str sizeWithFont:font];
        
        if(life > 9)
            x_offset = 1.2;
        if(life > 100 - CELLS)
            x_offset = 1.05;
        if(life > 99)
            x_offset = 1.1;
        if(life > 1000 - CELLS)
            x_offset = 0.95;
        if(life > 999)
            x_offset = 1;
        
        CGContextSetTextDrawingMode(context, kCGTextFill);
        CGContextShowTextAtPoint(context, 
                                 margin + col * cellWidth + cellWidth/2 - txtSize.width/2*x_offset,
                                 margin + row * cellHeight + (cellHeight + txtSize.height)/2*y_offset,
                                 txt, strlen(txt));
        
        //CGContextSetTextDrawingMode(context, kCGTextStroke);
        //CGContextShowTextAtPoint(context, 
        //                         margin + col * cellWidth + cellWidth/2 - txtSize.width/2, 
        //                         margin + row * cellHeight + (cellHeight + txtSize.height)/2*0.9, 
        //                         txt, strlen(txt));
       
    }
}

- (CGPoint) getTopLeftCellCenter
{
    return CGPointMake(margin + cellWidth/2, margin + cellHeight/2);
}

- (CGPoint)cropMarblePos:(CGPoint) pos
{
    
    float x_margin = cellWidth/2;
    float y_margin = cellHeight/2.5;
    
    if(parent != nil)
    {
        CGRect allowed = [parent getMarbleFieldFrame];
        
        if(pos.x - x_margin - allowed.origin.x < margin)
            pos = CGPointMake(margin + x_margin + allowed.origin.x, pos.y);
        else if(pos.x + x_margin > allowed.origin.x + allowed.size.width - margin)
            pos = CGPointMake(allowed.origin.x + allowed.size.width - margin - x_margin, pos.y);
        
        if(pos.y - y_margin - allowed.origin.y < margin)
            pos = CGPointMake(pos.x, margin + y_margin + allowed.origin.y);
        else if(pos.y + y_margin > allowed.origin.y + allowed.size.height - margin)
            pos = CGPointMake(pos.x, allowed.origin.y + allowed.size.height - margin - y_margin);
    }
    
    return pos;
}

- (void) showMarble:(UIImageView*)marbleView withValue:(int)lifeAmount
{
    if (marble != NULL) {
        [marble removeFromSuperview];
    }
    marble = marbleView;
    
    if(marble != NULL && marblesSurface != NULL)
    {
        int col = (lifeBase + CELLS - lifeAmount) % COLS;
        int row = (lifeBase + CELLS - lifeAmount) / COLS;
    
        marble.frame = CGRectMake(0, 0, marble.frame.size.width, marble.frame.size.height);
        CGPoint centerPoint = CGPointMake([self getTopLeftCellCenter].x + cellWidth * col, [self getTopLeftCellCenter].y + cellHeight * row);
        centerPoint = [marblesSurface convertPoint:centerPoint fromView:self];
        marble.center = [self cropMarblePos:centerPoint];
        
        [marblesSurface addSubview:marble];
    }
}

#pragma mark ContentView

- (void)contentView:(ContentView*)view didBeganTouch:(UITouch*)touch
{
    if(!marble_tracking && marble != nil && marblesSurface != nil)
    {
        CGPoint pos = [touch locationInView:marblesSurface];
        CGPoint marblePos = marble.center;
        if((sqrt(pow(marblePos.x - pos.x, 2) + pow(marblePos.y - pos.y, 2))) <= activeRadius)
        {
            NSLog(@"marble touch began");
            marble_tracking = YES;
            moveOffset = CGPointMake(pos.x - marblePos.x, pos.y - marblePos.y);
        }
    }
}

-(void)animateMarbleToCellCenter
{
    if( marble != nil && marblesSurface != nil)
    {
        CGPoint marblePos = [self convertPoint:marble.center fromView:marblesSurface];
        int col = (marblePos.x - margin) / cellWidth;
        int row = (marblePos.y - margin) / cellHeight;
        
        // Animation
        float distance = sqrt(pow([self getTopLeftCellCenter].x + cellWidth * col - marblePos.x, 2) +
                              pow([self getTopLeftCellCenter].y + cellHeight * row - marblePos.y, 2));
        float velocity = cellWidth/2; // px/s
        duration = distance/velocity + 0.2;
        [UIView beginAnimations:@"moveMarble" context:(void*)0];
        [UIView setAnimationDuration:(duration)];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDuringAnimation:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        animationStartTime = CACurrentMediaTime();
        CGPoint animationEndPos = CGPointMake([self getTopLeftCellCenter].x + cellWidth * col, [self getTopLeftCellCenter].y + cellHeight * row);
        
        animationDx = animationEndPos.x - marblePos.x;
        animationDy = animationEndPos.y - marblePos.y;
        marble.center = [self cropMarblePos:[marblesSurface convertPoint:animationEndPos fromView:self]];

        [UIView commitAnimations];
    }

}

- (void)contentView:(ContentView*)view didEndTouch:(UITouch*)touch
{
    if(marble_tracking)
    {
        NSLog(@"marble touch ended");
        marble_tracking = NO;
        
        CGPoint marblePos = [self convertPoint:marble.center fromView:marblesSurface];
        int col = (marblePos.x - margin) / cellWidth;
        int row = (marblePos.y - margin) / cellHeight;
        int lifeAmount = lifeBase + (COLS * (ROWS - row)) - col;
        
        if(self.parent != nil)
            [self.parent setPlayerLifeAmount:lifeAmount];
        
        [self animateMarbleToCellCenter];
    }
    else
    {
        // Field end touch
        
        [self animateMarbleToCellCenter];
    }
}

- (void)contentView:(ContentView*)view didMoveTouch:(UITouch*)touch
{

    if(marble_tracking && marble != nil && marblesSurface != nil)
    {
        // Move marble
        
        //NSLog(@"marble touch move");
        CGPoint pos = [touch locationInView:marblesSurface];
        
        marble.center = [self cropMarblePos:CGPointMake(pos.x - moveOffset.x, pos.y - moveOffset.y)];
        
        if(parent != nil)
            [self.parent marbleMovedTo:marble.center];
    }
    else
    {
        // Move field
        
        if(parent != nil)
        {
            CGFloat delta = [touch locationInView:self].y - [touch previousLocationInView:self].y;
            CGFloat actualMoved = [self.parent moveCardField:delta];
            
            if(marblesSurface != nil  && marble != nil)
            {
                marble.center = [self cropMarblePos:CGPointMake(marble.center.x, marble.center.y + actualMoved)];
                [self.parent marbleMovedTo:marble.center];
                
                CGPoint marblePos = [self convertPoint:marble.center fromView:marblesSurface];
                int col = (marblePos.x - margin) / cellWidth;
                int row = (marblePos.y - margin) / cellHeight;
                int lifeAmount = lifeBase + (COLS * (ROWS - row)) - col;
                [self.parent setPlayerLifeAmount:lifeAmount];
            }
        }
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [displayLink invalidate];
    if(parent != nil)
        [parent marbleMovedTo:marble.center];
}

- (void)updateDuringAnimation:(CADisplayLink*)displayLinkParam
{
    // update marble position while it moving

    float animationTime = CACurrentMediaTime() - animationStartTime;
    if(parent != nil){
        CGFloat x = marble.center.x - animationDx + animationDx/duration*animationTime;
        CGFloat y = marble.center.y - animationDy + animationDy/duration*animationTime;
        CGPoint pos = CGPointMake(x,y);
        [parent marbleMovedTo:pos];
    }
}

- (void) setLifeBase:(int)value
{
    lifeBase = value;
    labelsLifeBase = value;
    [self setNeedsDisplay];
}

@end
