//
//  DiceView.m
//  MTG LifeCounter
//
//  Created by bevz on 23/10/15.
//
//

#import "DiceView.h"
#import "CubeShader.h"
#import "CUBE_OBJ.h"
#import "CUBE_MTL.h"
#import "CC3GLMatrix.h"

#define NEAR 40.0
#define FAR 60.0
#define PV_WIDTH 10.0
#define SHIFT_Z 57.0
#define SCALE_FACTOR 2

#define ACCELERATION -10


@interface DiceView ()
{
    float Vx, Vy, X0, Y0;
    float x, y;
    CFTimeInterval _throwStartTime;
    
    CGPoint     dice_throw_start;
    CGPoint     dice_throw_end;
    double      dice_throw_time;
    double      dice_previous_move_time;
    Boolean     dice_locked;
    int         diceTouchCounter;
    
    CC3GLMatrix *savedRotation;
    float       interval;
}

@property (strong, nonatomic) CubeShader* cubeShader;

@end

@implementation DiceView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    // Create an OpenGL ES context and assign it to the view loaded from storyboard
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    // Configure renderbuffers created by the view
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    self.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
    
    // Enable multisampling
    self.drawableMultisample = GLKViewDrawableMultisample4X;
    glEnable(GL_DEPTH_TEST);
    
    [self loadShader];
    Vx = Vy = x = y = X0 = Y0 = 0;
    savedRotation = NULL;
    
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    return self;
}

- (void)loadShader
{
    self.cubeShader = [[CubeShader alloc] init];
    glUseProgram(self.cubeShader.program);
}

#pragma mark - Render
- (CC3Vector)findLowestPlane
{
    CC3Vector lowest = CC3VectorMake(0, 0, -1);
    if(savedRotation != NULL)
    {
        CC3Vector up = [savedRotation extractUpDirection];
        CC3Vector forward = [savedRotation extractForwardDirection];
        CC3Vector right = [savedRotation extractRightDirection];
        
        lowest = up;
        if(forward.z < lowest.z)
            lowest = forward;
        if(right.z < lowest.z)
            lowest = right;
        
        // check inverted
        if(-up.z < lowest.z)
            lowest = CC3VectorNegate(up);
        if(-forward.z < lowest.z)
            lowest = CC3VectorNegate(forward);
        if(-right.z < lowest.z)
            lowest = CC3VectorNegate(right);
        
    }
    return lowest;
}

- (void)setMatrices
{
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    
    // Projection Matrix
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    [projection populateFromFrustumLeft:-PV_WIDTH/2 andRight:PV_WIDTH/2 andBottom:-PV_HEIGTH/2 andTop:PV_HEIGTH/2 andNear:NEAR andFar:FAR];
    glUniformMatrix4fv(self.cubeShader.uProjectionMatrix, 1, GL_FALSE, projection.glMatrix);
    
    // ModelView Matrix
    float t = interval;
    float _Wx, _Wy;
    
    // move
    if(Vx || Vy)
    {
        // modify velocity
        float V = sqrtf(Vx*Vx + Vy*Vy);
        Vx = Vx > 0? MAX(0, Vx + ACCELERATION * Vx / V * t) : MIN(0, Vx + ACCELERATION * Vx / V * t);
        Vy = Vy > 0? MAX(0, Vy + ACCELERATION * Vy / V * t) : MIN(0, Vy + ACCELERATION * Vy / V * t);
        
        // add cube angle correction
        CC3Vector planeNormal = [self findLowestPlane];
        Vx += planeNormal.x * 0.7;
        Vy += planeNormal.y * 0.7;
        
        _Wy = (Vx * t)*RadiansToDegreesFactor;
        _Wx = -(Vy * t)*RadiansToDegreesFactor;
        
        x += Vx*t;
        y += Vy*t;
        
        // stop
        if(ABS(Vx) < 0.15) Vx = 0;
        if(ABS(Vy) < 0.15) Vy = 0;
        
        // if cube is stoped not horizontal, add velocity
        if(!Vx && !Vy)
        {
            if(ABS(planeNormal.x) > 0.1 || ABS(planeNormal.y) > 0.1)
            {
                Vx += planeNormal.x * 4;
                Vy += planeNormal.y * 4;
                
                NSLog(@"Add velocity. Vx: %g, Vy: %g", Vx, Vy);
            }
            
            if(ABS(planeNormal.x) < 0.1)
                _Wy = planeNormal.x * RadiansToDegreesFactor;
            
            if(ABS(planeNormal.y) < 0.1)
                _Wx = - planeNormal.y * RadiansToDegreesFactor;
        }
    }
    else
    {
        CC3Vector planeNormal = [self findLowestPlane];
        if(planeNormal.x || planeNormal.y)
        {
            _Wy = planeNormal.x * RadiansToDegreesFactor;
            _Wx = - planeNormal.y * RadiansToDegreesFactor;
            NSLog(@"PlaneNormal: [%g, %g, %g]. Make horizontal.", planeNormal.x, planeNormal.y, planeNormal.z);
        }
        else
        {
            _Wx = 0;
            _Wy = 0;
        }
    }
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(x, y, -SHIFT_Z)];
    [modelView scaleBy:CC3VectorMake(SCALE_FACTOR, SCALE_FACTOR, SCALE_FACTOR)];
    
    // test for field walls - invert future velocity
    if(x + 1 > (SHIFT_Z-1)/NEAR*PV_WIDTH/2)
    {
        x = (SHIFT_Z-1)/NEAR*PV_WIDTH/2 - 1;
        Vx = -Vx;
    }
    if(x - 1 < -(SHIFT_Z-1)/NEAR*PV_WIDTH/2)
    {
        x = -(SHIFT_Z-1)/NEAR*PV_WIDTH/2 + 1;
        Vx = -Vx;
    }
    if(y + 1 > (SHIFT_Z-1)/NEAR*PV_HEIGTH/2)
    {
        y = (SHIFT_Z-1)/NEAR*PV_HEIGTH/2 - 1;
        Vy = -Vy;
    }
    if(y - 1 < -(SHIFT_Z-1)/NEAR*PV_HEIGTH/2)
    {
        y = -(SHIFT_Z-1)/NEAR*PV_HEIGTH/2 + 1;
        Vy = -Vy;
    }
    
    // make current rotation matrix
    CC3GLMatrix *rotateMatrix = [CC3GLMatrix matrix];
    [rotateMatrix populateIdentity];
    
    if(_Wx || _Wy)
    {
        // add rotation
        CC3Vector rotateVector = CC3VectorMake(_Wx, _Wy, 0);
        [rotateMatrix populateFromRotation:rotateVector];
    }
    
    // apply saved rotation state to current rotation and save result
    if (savedRotation == NULL)
    {
        savedRotation = [CC3GLMatrix matrix];
        [savedRotation populateIdentity];
    }
    [rotateMatrix multiplyByMatrix:savedRotation];
    [savedRotation populateFrom:rotateMatrix];
    
    // rotate model
    [modelView multiplyByMatrix:rotateMatrix];

    glUniformMatrix4fv(self.cubeShader.uModelViewMatrix, 1, GL_FALSE, modelView.glMatrix);
    
    // Normals matrix
    bool invertible;
    GLKMatrix3 normalMatrix = GLKMatrix4GetMatrix3(GLKMatrix4InvertAndTranspose(GLKMatrix4MakeWithArray(modelView.glMatrix), &invertible));
    if(!invertible)
        NSLog(@"MV matrix is not invertible");
    glUniformMatrix3fv(self.cubeShader.uNormalMatrix, 1, 0, normalMatrix.m);
}

- (void)render:(CADisplayLink*)displayLink{
    interval = displayLink.duration;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Set matrices
    [self setMatrices];
    
    // Positions
    glEnableVertexAttribArray(self.cubeShader.aPosition);
    //glVertexAttribPointer(self.phongShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, starshipPositions);
    glVertexAttribPointer(self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, CUBE_Verts);
    
    // Normals
    glEnableVertexAttribArray(self.cubeShader.aNormal);
    //glVertexAttribPointer(self.phongShader.aNormal, 3, GL_FLOAT, GL_FALSE, 0, starshipNormals);
    glVertexAttribPointer(self.cubeShader.aNormal, 3, GL_FLOAT, GL_FALSE, 0, CUBE_Normals);
    
    // Render by parts
    //for(int i=0; i<starshipMaterials; i++)
    for(int i=0; i<CUBE_NumMaterials; i++)
    {
        // Set material
        //glUniform3f(self.phongShader.uDiffuse, starshipDiffuses[i][0], starshipDiffuses[i][1], starshipDiffuses[i][2]);
        glUniform3f(self.cubeShader.uDiffuse, CUBE_Diffuse[i][0], CUBE_Diffuse[i][1], CUBE_Diffuse[i][2]);
        //glUniform3f(self.phongShader.uSpecular, starshipSpeculars[i][0], starshipSpeculars[i][1], starshipSpeculars[i][2]);
        glUniform3f(self.cubeShader.uSpecular, CUBE_Specular[i][0], CUBE_Specular[i][1], CUBE_Specular[i][2]);
        
        // Draw vertices
        glDrawArrays(GL_TRIANGLES, CUBE_First[i], CUBE_Count[i]);
    }

}

#pragma mark - External dice control

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    return [self diceTouched:point] ? self : nil;
}

-(void) throwDice:(float)time withX0:(float)x0 withY0:(float)y0
{
    float velocity = sqrtf(powf(x0,2) + powf(y0, 2))/time;
    Vx = x0 / time / MAX(1, sqrtf(ABS(30.0 - velocity)));
    Vy = y0 / time / MAX(1, sqrtf(ABS(30.0 - velocity)));
    
    _throwStartTime = CACurrentMediaTime();
    NSLog(@"Dice throw: %g:%g time: %g", x0, y0, time);
}

-(void) moveDice:(CGSize)delta
{
    // translate to scene coords
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    float dx = delta.width/self.bounds.size.width*PV_WIDTH*FAR/NEAR;
    float dy = -delta.height/self.bounds.size.height*PV_HEIGTH*FAR/NEAR;
    
    x += dx; X0 = x;
    y += dy; Y0 = y;
}

-(BOOL) diceTouched:(CGPoint)pos
{
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    CGPoint posInScene;
    posInScene.x = (pos.x - self.bounds.size.width/2)/self.bounds.size.width*PV_WIDTH*FAR/NEAR;
    posInScene.y = -(pos.y - self.bounds.size.height/2)/self.bounds.size.height*PV_HEIGTH*FAR/NEAR;
    float distance = sqrtf(powf(posInScene.x - x, 2) + powf(posInScene.y - y, 2));
    //NSLog(@"Touch distance: %g", distance);
    return distance < 1.4;
}

# pragma mark - Touches Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    if([self diceTouched:[touch locationInView:self]])
    {
        //NSLog(@"dice touch began");
        dice_throw_start = [touch locationInView:self];
        dice_previous_move_time = CACurrentMediaTime();
        dice_locked = YES;
        diceTouchCounter = 0;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchCancelled");
    
    dice_locked = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchEnded");
    
    if(dice_locked)
    {
        UITouch* touch = [touches anyObject];
        dice_throw_end = [touch locationInView:self];
        dice_throw_time = CACurrentMediaTime();
        //NSLog(@"time: %f", dice_throw_time);
        dice_locked = NO;
        
        if(dice_throw_time - dice_previous_move_time < 0.3)
        {
            float dx = (dice_throw_end.x-dice_throw_start.x);
            float dy = (dice_throw_start.y-dice_throw_end.y);
            float dl = sqrt(powf(dx,2) + powf(dy, 2));
            if(dl != 0)
                [self throwDice:MAX(dice_throw_time - dice_previous_move_time, 0.01) withX0:dx withY0:dy];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(dice_locked)
    {
        UITouch* touch = [touches anyObject];
        CGSize shift = CGSizeMake([touch locationInView:self].x - [touch previousLocationInView:self].x, [touch locationInView:self].y - [touch previousLocationInView:self].y);
        [self moveDice:shift];
        
        dice_throw_end = [touch locationInView:self];
        
        diceTouchCounter++;
        if(diceTouchCounter < 5)
            return;
        diceTouchCounter = 0;
        
        dice_previous_move_time = CACurrentMediaTime();
        dice_throw_start = [touch previousLocationInView:self];
        //NSLog(@"touchMoved: [%g,%g]", shift.width, shift.height);
    }
}

@end
