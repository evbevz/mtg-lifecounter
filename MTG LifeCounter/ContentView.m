
#import "ContentView.h"

@implementation ContentView

@synthesize delegate;



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"touchBegan");
    
    UITouch* touch = [touches anyObject];
    if ([self.delegate respondsToSelector:@selector(contentView:didBeganTouch:)])
    {
        [self.delegate contentView:self didBeganTouch:touch];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchCancelled");

    UITouch* touch = [touches anyObject];
    if ([self.delegate respondsToSelector:@selector(contentView:didCancelTouch:)])
    {
        [self.delegate contentView:self didCancelTouch:touch];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchEnded");

    UITouch* touch = [touches anyObject];
    if ([self.delegate respondsToSelector:@selector(contentView:didEndTouch:)])
    {
        [self.delegate contentView:self didEndTouch:touch];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchMoved");

    UITouch* touch = [touches anyObject];
    if ([self.delegate respondsToSelector:@selector(contentView:didMoveTouch:)])
    {
        [self.delegate contentView:self didMoveTouch:touch];
    }
}

@end
