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
#define SCALE_FACTOR 1.5

#define ACCELERATION -10
#define MAX_ROLL_DURATION 3.0               // sec
#define MAX_DURATION_CORRECTION_WEIGHT 0.1

#define DICE_VELOCITY_STOP_THRESHOLD 1.5   // pix/sec
#define DICE_EDGE_ANGLE_CORRECTION_WEIGHT 1.7

#define MARBLES 5

#define DRAW_DATA 1

@interface DiceView ()
{
    float Vx, Vy;
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
    CGPoint     diceDefaultPlace;
    
    float       marbleRadius;
    CGPoint     marblesCoords[MARBLES];
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
    Vx = Vy = x = y = 0;
    savedRotation = NULL;
    marbleRadius = 0;
    for (unsigned int i = 0; i < MARBLES; ++i) {
        marblesCoords[i] = CGPointMake(NAN, NAN);
    }
    
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

- (CGPoint)testMarblesHit:(float)time
{
    CGPoint res = CGPointMake(NAN, NAN);
    
    
    if(sqrt(Vx*time*Vx*time + Vy*time*Vy*time) < marbleRadius)
        return res; // marble is too far
    
    // test for marbles hit
    //if(sqrt(pow(x - marblesCoords[0].x, 2) + pow(y - marblesCoords[0].y, 2)) < marbleRadius)
    {
        float r = marbleRadius;
        float x2 = x + Vx*time;
        float y2 = y + Vy*time;
        float a = y - y2;
        float b = x2 - x;
        float c = x*y2 - x2*y;
        
        float x0 = -a*c/(a*a+b*b),  y0 = -b*c/(a*a+b*b);
        if (c*c > r*r*(a*a+b*b)+FLT_EPSILON)
            return CGPointMake(NAN, NAN);
        
        if (fabsf (c*c - r*r*(a*a+b*b)) < FLT_EPSILON)
            return CGPointMake(x0, y0);
        
        float d = r*r - c*c/(a*a+b*b);
        float mult = sqrt (d / (a*a+b*b));
        float ax,ay,bx,by;
        ax = x0 + b * mult;
        bx = x0 - b * mult;
        ay = y0 - a * mult;
        by = y0 + a * mult;

        if(sqrt((x-ax)*(x-ax)+(y-ay)*(y-ay)) < sqrt((x-bx)*(x-bx)+(y-by)*(y-by)))
            return CGPointMake(ax, ay);
        else
            return CGPointMake(bx, by);
        
    }
    
    return CGPointMake(NAN, NAN);
}

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
        CC3Vector planeNormal = [self findLowestPlane];

        // make acceleration dependent from lower plane orientation
        float acceleration = ACCELERATION / MAX(0.05, sqrt(pow(planeNormal.x, 2) + pow(planeNormal.y, 2)));
        
        // modify velocity - linear acceleration
        float V = sqrtf(Vx*Vx + Vy*Vy);
        Vx = Vx > 0? MAX(0, Vx + acceleration * Vx / V * t) : MIN(0, Vx + acceleration * Vx / V * t);
        Vy = Vy > 0? MAX(0, Vy + acceleration * Vy / V * t) : MIN(0, Vy + acceleration * Vy / V * t);
        
        // velocity - apply max roll duration limit
        float roll_time = MIN(CACurrentMediaTime() - _throwStartTime, MAX_ROLL_DURATION);
        float correction = pow((MAX_ROLL_DURATION - roll_time) / MAX_ROLL_DURATION, MAX_DURATION_CORRECTION_WEIGHT);
        Vx = Vx * correction;
        Vy = Vy * correction;
        
        // add cube angle correction
        Vx += planeNormal.x * DICE_EDGE_ANGLE_CORRECTION_WEIGHT;
        Vy += planeNormal.y * DICE_EDGE_ANGLE_CORRECTION_WEIGHT;
        
        _Wy = (Vx * t)*RadiansToDegreesFactor;
        _Wx = -(Vy * t)*RadiansToDegreesFactor;
    
        //CGPoint hitPoint = [self testMarblesHit:t];
        //if(hitPoint.x != NAN) {
        //    x = hitPoint.x;
        //    y = hitPoint.y;
        //}
        //else {
            x += Vx*t;
            y += Vy*t;
        //}
        
        // stop
        if(ABS(Vx) < DICE_VELOCITY_STOP_THRESHOLD) Vx = 0;
        if(ABS(Vy) < DICE_VELOCITY_STOP_THRESHOLD) Vy = 0;
        
        // if cube is stoped not horizontal, add velocity
        if(!Vx && !Vy)
        {
            if(ABS(planeNormal.x) > 0.1 || ABS(planeNormal.y) > 0.1)
            {
                    Vx += planeNormal.x * (0.7 - ABS(planeNormal.x)) * 40;
                    Vy += planeNormal.y * (0.7 - ABS(planeNormal.y)) * 40;
                
                NSLog(@"Add velocity. Normal (%g, %g). Vx: %g, Vy: %g", planeNormal.x, planeNormal.y, Vx, Vy);
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
            _Wy = asin(planeNormal.x) * RadiansToDegreesFactor;
            _Wx = -asin(planeNormal.y) * RadiansToDegreesFactor;
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
    glVertexAttribPointer(self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, CUBE_Verts);
    
    // Normals
    glEnableVertexAttribArray(self.cubeShader.aNormal);
    glVertexAttribPointer(self.cubeShader.aNormal, 3, GL_FLOAT, GL_FALSE, 0, CUBE_Normals);
    
    // Render by parts
    for(int i=0; i<CUBE_NumMaterials; i++)
    {
        // Set material
        glUniform3f(self.cubeShader.uDiffuse, CUBE_Diffuse[i][0], CUBE_Diffuse[i][1], CUBE_Diffuse[i][2]);
        glUniform3f(self.cubeShader.uSpecular, CUBE_Specular[i][0], CUBE_Specular[i][1], CUBE_Specular[i][2]);
        
        // Draw vertices
        glDrawArrays(GL_TRIANGLES, CUBE_First[i], CUBE_Count[i]);
    }
    
    // Draw data
    if(DRAW_DATA)
    {
        CC3GLMatrix *modelView = [CC3GLMatrix matrix];
        [modelView populateFromTranslation:CC3VectorMake(0, 0, -SHIFT_Z)];

        glUniformMatrix4fv(self.cubeShader.uModelViewMatrix, 1, GL_FALSE, modelView.glMatrix);
        glUniform3f(self.cubeShader.uDiffuse, 1.0, 1.0, 1.0);
        glUniform3f(self.cubeShader.uSpecular, 0.0, 0.0, 0.0);
        
        for (unsigned int mi = 0; mi < MARBLES; ++mi) {
            if(marblesCoords[mi].x == NAN)
                continue;
            
            int segments = 30;
            GLfloat vertices[segments*3];
            int count=0;
            for (GLfloat i = 0; i < 360.0f; i+=(360.0f/segments))
            {
                vertices[count++] = marblesCoords[mi].x + (cos(DegreesToRadians(i))*marbleRadius);
                vertices[count++] = marblesCoords[mi].y + (sin(DegreesToRadians(i))*marbleRadius);
                vertices[count++] = -2.8;
            }
            glVertexAttribPointer (self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
            glDrawArrays(GL_LINE_LOOP, 0, segments);
        }
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
    
    x += dx;
    y += dy;
}

-(void) moveDiceTo:(CGPoint)pos
{
    // translate to scene coords
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    x = (pos.x - self.bounds.size.width/2)/self.bounds.size.width*PV_WIDTH*FAR/NEAR;
    y = -(pos.y - self.bounds.size.height/2)/self.bounds.size.height*PV_HEIGTH*FAR/NEAR;
}

-(void) moveDiceToDefaultPlace
{
    [self moveDiceTo:diceDefaultPlace];
}


-(void) setDiceDefaultPlace:(CGPoint)pos
{
    diceDefaultPlace = pos;
    [self moveDiceTo:diceDefaultPlace];
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

-(void) setMarblesCoords:(CGPoint [])marbles andCount:(int)count withRadius:(float)radius
{
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    for (unsigned int i = 0; i < MARBLES; ++i) {
        if(i < count){
            // translate to scene coords
            CGPoint pos = marbles[i];
            float mx = (pos.x - self.bounds.size.width/2)/self.bounds.size.width*PV_WIDTH*FAR/NEAR;
            float my = -(pos.y - self.bounds.size.height/2)/self.bounds.size.height*PV_HEIGTH*FAR/NEAR;
            marblesCoords[i] = CGPointMake(mx, my);
            //NSLog(@"Marble coord: [%g, %g]", mx, my);
        }
        else
            marblesCoords[i] = CGPointMake(NAN, NAN);
    }
    marbleRadius = radius/self.bounds.size.width*PV_WIDTH*FAR/NEAR;
    //NSLog(@"Marble radius: %g", marbleRadius);
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
