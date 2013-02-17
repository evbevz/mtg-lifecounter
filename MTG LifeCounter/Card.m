//
//  Card.m
//  MTG LifeCounter
//
//  Created by Mac on 10.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Card.h"



@interface CardView() 
{
}

-(void)drawBorder:(CGRect)rect :(CGContextRef)context;
-(void)drawNet:(CGRect)rect :(CGContextRef)context;
-(void)drawLabels:(CGRect)rect :(CGContextRef)context;

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


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        margin = 5;
        lifeBase = 0;
        linesColor = [UIColor blackColor];
        fontColor = [UIColor blackColor];
        font = [UIFont systemFontOfSize:20.0];
        marble_tracking = false;
        self.delegate = self;
        parent = nil;
                
    }
    

    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSLog(@"CardView:drawRect");
    
    cellWidth = (rect.size.width - 2*margin) / 4;
    cellHeight = (rect.size.height - 2*margin) /5;
    activeRadius = MIN(cellHeight, cellWidth) / 2 * 0.8;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetStrokeColorWithColor(context, linesColor.CGColor);
    //CGContextSetFillColorWithColor(context, linesColor.CGColor);
   //CGContextClearRect(context, rect);
    
    if(backgroundImage)
        [backgroundImage drawInRect:rect];
    
    [self drawBorder:rect:context];
    [self drawNet:rect:context];
    [self drawLabels:rect:context];
}

- (void)drawBorder:(CGRect)rect :(CGContextRef)context
{
    CGContextStrokeRect(context, CGRectMake(rect.origin.x + margin, rect.origin.y + margin, rect.size.width - 2*margin, rect.size.height - 2*margin));
}


- (void)drawNet:(CGRect)rect :(CGContextRef)context
{
    CGPoint p[2];
    
    for(int lines = 1; lines < 5; ++lines)
    {
        p[0] = CGPointMake(margin, margin + lines * cellHeight);
        p[1] = CGPointMake(rect.size.width - margin, p[0].y);
        CGContextStrokeLineSegments(context, p, 2);
    }

    for(int lines = 1; lines < 4; ++lines)
    {
        p[0] = CGPointMake(margin + lines * cellWidth, margin);
        p[1] = CGPointMake(p[0].x, rect.size.height - margin);
        CGContextStrokeLineSegments(context, p, 2);
    }

}

- (void)drawLabels:(CGRect)rect :(CGContextRef)context
{
    float y_offset = 1;
    float x_offset = 1;
    
    y_offset = 0.85;
    CGContextSelectFont(context, font.fontName.UTF8String, font.lineHeight, kCGEncodingMacRoman);
    if(lifeBase >= 80)
    {
        y_offset = 0.8;
        CGContextSelectFont(context, font.fontName.UTF8String, font.lineHeight * 0.9, kCGEncodingMacRoman);
    }
    if(lifeBase >= 980)
    {
        y_offset = 0.8;
        CGContextSelectFont(context, font.fontName.UTF8String, font.lineHeight * 0.8, kCGEncodingMacRoman);
    }
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetTextMatrix(context, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
    CGContextSetFillColorWithColor(context, fontColor.CGColor);
    CGContextSetStrokeColorWithColor(context,fontBorderColor.CGColor);
    
    char txt[5];
    for(int life = lifeBase + 20; life > lifeBase; --life)
    {
        sprintf(txt, "%d", life);
        
        float cellWidth = (rect.size.width - 2*margin)/4;
        float cellHeight = (rect.size.height - 2*margin)/5;
        
        int col = (lifeBase + 20 - life) % 4;
        int row = (lifeBase + 20 - life) / 4;
        //NSLog(@"col = %d \t row = %d", col, row);
        
        NSString *str = [[NSString alloc] initWithUTF8String:txt];
        CGSize txtSize = [str sizeWithFont:font];
        
        if(life > 9)
            x_offset = 1.2;
        if(life > 80)
            x_offset = 1.05;
        if(life > 99)
            x_offset = 1.1;
        if(life > 980)
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

- (void) showMarble:(UIImageView*)marbleView withValue:(int)lifeAmount
{
    if (marble != NULL) {
        [marble removeFromSuperview];
    }
    marble = marbleView;
    
    if(marble != NULL)
    {
        int col = (lifeBase + 20 - lifeAmount) % 4;
        int row = (lifeBase + 20 - lifeAmount) / 4;
    
        marble.frame = CGRectMake(0, 0, marble.frame.size.width, marble.frame.size.height);
        marble.center = CGPointMake([self getTopLeftCellCenter].x + cellWidth * col, [self getTopLeftCellCenter].y + cellHeight * row);
    
        [self addSubview:marble];
    }
}


#pragma mark ContentView

- (void)contentView:(ContentView*)view didBeganTouch:(UITouch*)touch
{
    CGPoint pos = [touch locationInView:self];
    if(!marble_tracking && marble != nil && (sqrt(pow(marble.center.x - pos.x, 2) + pow(marble.center.y - pos.y, 2))) <= activeRadius)
    {
        NSLog(@"marble touch began");
        marble_tracking = YES;
        moveOffset = CGPointMake(pos.x - marble.center.x, pos.y - marble.center.y);
    }
}

- (void)contentView:(ContentView*)view didEndTouch:(UITouch*)touch
{
    if(marble_tracking && marble != nil)
    {
        NSLog(@"marble touch ended");
        marble_tracking = NO;
        
        int col = (marble.center.x - margin) / cellWidth;
        int row = (marble.center.y - margin) / cellHeight;
        int lifeAmount = lifeBase + (4 * (5 - row)) - col;       

        if(self.parent != nil)
        {
            [self.parent setPlayerLifeAmount:lifeAmount];
        }
        
        // Animation
        float distance = sqrt(pow([self getTopLeftCellCenter].x + cellWidth * col - marble.center.x, 2) +
        pow([self getTopLeftCellCenter].y + cellHeight * row - marble.center.y, 2));
        float velocity = cellWidth/2; // px/s
        
        [UIView beginAnimations:@"flipCard" context:(void*)0];
        [UIView setAnimationDuration:(distance/velocity + 0.2)];
        [UIView setAnimationDelegate:self];
        
        marble.center = CGPointMake([self getTopLeftCellCenter].x + cellWidth * col, [self getTopLeftCellCenter].y + cellHeight * row);
        
        [UIView commitAnimations];
        
    }
}

- (void)contentView:(ContentView*)view didMoveTouch:(UITouch*)touch
{
    if(marble_tracking && marble != nil)
    {
        NSLog(@"marble touch move");
        CGPoint pos = [touch locationInView:self];
        CGPoint marblePos = marble.center;
        
        
        if(pos.x - moveOffset.x - cellWidth/3 < margin)
            marblePos = CGPointMake(margin + cellWidth/3, marblePos.y);
        else if(pos.x - moveOffset.x + cellWidth/3 > self.frame.size.width - margin)
            marblePos = CGPointMake(self.frame.size.width - margin - cellWidth/3, marblePos.y);
        else
            marblePos = CGPointMake(pos.x - moveOffset.x, marblePos.y);

        if(pos.y - moveOffset.y - cellHeight/4 < margin)
            marblePos = CGPointMake(marblePos.x, margin + cellHeight/4);
        else if(pos.y - moveOffset.y + cellHeight/4 > self.frame.size.height - margin)
            marblePos = CGPointMake(marblePos.x, self.frame.size.height - margin - cellHeight/4);
        else
            marblePos = CGPointMake(marblePos.x, pos.y - moveOffset.y);
        
        marble.center = marblePos;
    }
}


@end
