
@interface ContentView : UIView
{
    
    __unsafe_unretained id      delegate;

}

@property (nonatomic, assign)   id      delegate;

@end


@protocol ContentViewDelegate

- (void)contentView:(ContentView*)view didBeganTouch:(UITouch*)touch;
- (void)contentView:(ContentView*)view didMoveTouch:(UITouch*)touch;
- (void)contentView:(ContentView*)view didEndTouch:(UITouch*)touch;
- (void)contentView:(ContentView*)view didCancelTouch:(UITouch*)touch;

@end

