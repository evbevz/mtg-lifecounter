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


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        margin = 5;
        lifeBase = 0;
        linesColor = [UIColor blackColor];
        fontColor = [UIColor blackColor];
        font = [UIFont systemFontOfSize:20.0];
    }
    
    // Marble
    //marble = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MarbleBlue.png"]];
    //CGPoint coords = card.getTopLeftCellCenter;
    //marble_x = coords.x + card.frame.origin.x - marble.image.size.width * y_scale / 2;
    //marble_y = coords.y + card.frame.origin.y - marble.image.size.height * y_scale / 2;
    //marble.frame = CGRectMake(marble_x, marble_y, marble.image.size.width * y_scale, marble.image.size.height * y_scale);
    //[self.view addSubview:marble];

    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSLog(@"CardView:drawRect");
    
    CGContextRef context = UIGraphicsGetCurrentContext();
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
        p[0] = CGPointMake(margin, margin + lines * (rect.size.height - 2*margin) / 5);
        p[1] = CGPointMake(rect.size.width - margin, p[0].y);
        CGContextStrokeLineSegments(context, p, 2);
    }

    for(int lines = 1; lines < 4; ++lines)
    {
        p[0] = CGPointMake(margin + lines * (rect.size.width - 2*margin) / 4, margin);
        p[1] = CGPointMake(p[0].x, rect.size.height - margin);
        CGContextStrokeLineSegments(context, p, 2);
    }

}

- (void)drawLabels:(CGRect)rect :(CGContextRef)context
{
    CGContextSetTextMatrix(context, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
    CGContextSetStrokeColorWithColor(context, fontColor.CGColor);
    float cellWidth = (rect.size.width - 2*margin)/4;
    float cellHeight = (rect.size.height - 2*margin)/5;
    
    char txt[4];
    for(int life = lifeBase + 20; life > lifeBase; --life)
    {
        sprintf(txt, "%d", life);
        CGContextSelectFont(context, font.fontName.UTF8String, font.lineHeight, kCGEncodingMacRoman);
        CGContextSetTextDrawingMode(context, kCGTextStroke);
        
        int col = (lifeBase + 20 - life) % 4;
        int row = (lifeBase + 20 - life) / 4;
        //NSLog(@"col = %d \t row = %d", col, row);
        
        NSString *str = [[NSString alloc] initWithUTF8String:txt];
        CGSize txtSize = [str sizeWithFont:font];
        
        CGContextShowTextAtPoint(context, 
                                 margin + col * cellWidth + cellWidth/2 - txtSize.width/2, 
                                 margin + row * cellHeight + (cellHeight + txtSize.height)/2*0.9, 
                                 txt, strlen(txt));
        
       
    }
}

- (CGPoint) getTopLeftCellCenter
{
    float cellWidth = (self.frame.size.width - 2*margin)/4;
    float cellHeight = (self.frame.size.height - 2*margin)/5;
    return CGPointMake(margin + cellWidth/2, margin + cellHeight/2);
}

#pragma mark ContentView
- (void)contentView:(ContentView*)view didMoveTouch:(UITouch*)touch
{
    //CGPoint point = [touch locationInView:self];
    //self.floatItem.center = point;
    
	//if(!_reverseAction)
	//	[self scrollFarmIfNeeded];
}


@end
