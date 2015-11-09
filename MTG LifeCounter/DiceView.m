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
#define DICE_RADIUS (0.7 * SCALE_FACTOR)
#define DICE_TO_MARBLE_MANUAL_HIT_MULTILIFIER 100

#define MAX_MARBLES 5

#define DRAW_DATA 0

@interface DiceView ()
{
    float Vx, Vy;
    float x, y;
    CFTimeInterval throwStartTime;
    
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
    CGPoint     marblesCoords[MAX_MARBLES];
    int         marblesCount;
    CGPoint     lastHitPoint;
    GLKVector2  reflection;
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
    marblesCount = 0;
    lastHitPoint = CGPointMake(NAN, NAN);
    reflection = GLKVector2Make(NAN, NAN);
    
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    /*
    float Z1 = 0, Z2 = 0, X1 = 0, X2 = 0, Y1 = 0, Y2 = 0;
    for(int i = 0; i < CUBE_NumVerts/3; i++)
    {
        X1 = MIN(CUBE_Verts[i], X1);
        X2 = MAX(CUBE_Verts[i], X2);
        Y1 = MIN(CUBE_Verts[i+1], Y1);
        Y2 = MAX(CUBE_Verts[i+1], Y2);
        Z1 = MIN(CUBE_Verts[i+2], Z1);
        Z2 = MAX(CUBE_Verts[i+2], Z2);
    }
    NSLog(@"Cube size: [%g x %g x %g]", ABS(X2 - X1), ABS(Y2 - Y1), ABS(Z2 - Z1));
    NSLog(@"Cube center: [%g, %g, %g", (X1 + X2)/2, (Y1 + Y2)/2, (Z1 + Z2)/2);
    */
        
    return self;
}

- (void)loadShader
{
    self.cubeShader = [[CubeShader alloc] init];
    glUseProgram(self.cubeShader.program);
}

#pragma mark - Render

- (CGPoint)testMarblesHit:(float)time withVx:(float)vx withVy:(float)vy
{
    CGPoint res = CGPointMake(NAN, NAN);
    CGPoint l; // last point in this turn
    bool wasHit = false;
    int marbleNum = -1;
    
    // test for marbles hit
    float r = marbleRadius + DICE_RADIUS;
    for(unsigned int m = 0; m < marblesCount; ++m)
    {
        // move coord to circle
        float x1 = x - marblesCoords[m].x;
        float y1 = y - marblesCoords[m].y;
        float x2 = x1 + vx*time;
        float y2 = y1 + vy*time;
        float a = y1 - y2;
        float b = x2 - x1;
        float c = x1*y2 - x2*y1;
        
        float x0 = -a*c/(a*a+b*b),  y0 = -b*c/(a*a+b*b);
        if (c*c > r*r*(a*a+b*b)+FLT_EPSILON)
            continue;
        
        // two intersection points exists (can to be the same)
        
        // check moving direction
        if(((vx > 0 && x1 > 0) || (vx < 0 && x1 < 0))
            && ((vy > 0 && y1 > 0) || (vy < 0 && y1 < 0)))
            continue;
        
        float d = r*r - c*c/(a*a+b*b);
        float mult = sqrt (d / (a*a+b*b));
        float ax,ay,bx,by;
        ax = x0 + b * mult;
        bx = x0 - b * mult;
        ay = y0 - a * mult;
        by = y0 + a * mult;

        CGPoint pA = CGPointMake(ax + marblesCoords[m].x, ay + marblesCoords[m].y); // move coords back
        CGPoint pB = CGPointMake(bx + marblesCoords[m].x, by + marblesCoords[m].y); // move coords back
        CGPoint p;
        // get nearest point
        if(sqrt((x1-ax)*(x1-ax)+(y1-ay)*(y1-ay)) < sqrt((x1-bx)*(x1-bx)+(y1-by)*(y1-by)))
            p = pA;
        else
            p = pB;
        
        // compare with last point in this turn
        if(wasHit && (sqrt((x - l.x)*(x - l.x) + (y - l.y)*(y - l.y)) < sqrt((x - p.x)*(x - p.x) + (y - p.y)*(y - p.y))))
            continue;
        else
        {
            l = p;
            marbleNum = m;
        }
        wasHit = true;
    }
    
    if(wasHit)
    {
        float x2 = x + vx*time;
        float y2 = y + vy*time;
        if(((x < l.x && l.x < x2) || (x > l.x && l.x > x2)) && ((y < l.y && l.y < y2) || (y > l.y && l.y > y2)))
            res = l; // hitPoint is between x and x2
        else if (sqrt(pow(x2 - marblesCoords[marbleNum].x, 2) + pow(y2 - marblesCoords[marbleNum].y, 2)) < r)
            res = l; // dice and marble is closer than radiuses summ
        
        GLKVector2 vI = GLKVector2Make(vx, vy);
        GLKVector2 vN = GLKVector2Normalize(GLKVector2Make(marblesCoords[marbleNum].x - res.x, marblesCoords[marbleNum].y - res.y));
        reflection = GLKVector2Subtract(vI, GLKVector2MultiplyScalar(vN, 2.0 * GLKVector2DotProduct(vN, vI)));

    }
    /*
    else
    {
        for(unsigned int im = 0; im < marblesCount; ++im)
        {
            if(GLKVector2Distance(GLKVector2Make(x, y), GLKVector2Make(marblesCoords[im].x, marblesCoords[im].y)) < r){
                NSLog(@"Error!");
            }
        }
    }
    */
    return res;
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
        float roll_time = MIN(CACurrentMediaTime() - throwStartTime, MAX_ROLL_DURATION);
        float correction = pow((MAX_ROLL_DURATION - roll_time) / MAX_ROLL_DURATION, MAX_DURATION_CORRECTION_WEIGHT);
        Vx = Vx * correction;
        Vy = Vy * correction;
        
        // add cube angle correction
        Vx += planeNormal.x * DICE_EDGE_ANGLE_CORRECTION_WEIGHT;
        Vy += planeNormal.y * DICE_EDGE_ANGLE_CORRECTION_WEIGHT;
        
        _Wy = (Vx * t)*RadiansToDegreesFactor;
        _Wx = -(Vy * t)*RadiansToDegreesFactor;
    
        CGPoint hitPoint = [self testMarblesHit:t withVx:Vx withVy:Vy];
        if(!isnan(hitPoint.x)) {
            lastHitPoint = hitPoint;
            x = hitPoint.x;
            y = hitPoint.y;
            Vx = reflection.x;
            Vy = reflection.y;
        }
        else {
            x += Vx*t;
            y += Vy*t;
        }
        
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
            //NSLog(@"PlaneNormal: [%g, %g, %g]. Make horizontal.", planeNormal.x, planeNormal.y, planeNormal.z);
        }
        else
        {
            _Wx = 0;
            _Wy = 0;
        }
    }
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateIdentity];
    [modelView translateBy:CC3VectorMake(x, y, -SHIFT_Z)];
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
        
        // marbles
        for (unsigned int mi = 0; mi < marblesCount; ++mi)
        {
            int segments = 30;
            GLfloat vertices[segments*3];
            int count=0;
            for (GLfloat i = 0; i < 360.0f; i+=(360.0f/segments))
            {
                vertices[count++] = marblesCoords[mi].x + (cos(DegreesToRadians(i))*marbleRadius);
                vertices[count++] = marblesCoords[mi].y + (sin(DegreesToRadians(i))*marbleRadius);
                vertices[count++] = 0;
            }
            glVertexAttribPointer (self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
            glDrawArrays(GL_LINE_LOOP, 0, segments);
            
            // and hit zones
            count=0;
            for (GLfloat i = 0; i < 360.0f; i+=(360.0f/segments))
            {
                vertices[count++] = marblesCoords[mi].x + (cos(DegreesToRadians(i))*(marbleRadius + DICE_RADIUS));
                vertices[count++] = marblesCoords[mi].y + (sin(DegreesToRadians(i))*(marbleRadius + DICE_RADIUS));
                vertices[count++] = 0;
            }
            glVertexAttribPointer (self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
            glDrawArrays(GL_LINE_LOOP, 0, segments);
        }
        
        // hitPoint
        if(!isnan(lastHitPoint.x))
        {
            int segments = 10;
            GLfloat vertices[segments*3];
            int count=0;
            for (GLfloat i = 0; i < 360.0f; i+=(360.0f/segments))
            {
                vertices[count++] = lastHitPoint.x + (cos(DegreesToRadians(i))*0.2);
                vertices[count++] = lastHitPoint.y + (sin(DegreesToRadians(i))*0.2);
                vertices[count++] = 0;
            }
            glVertexAttribPointer (self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
            glDrawArrays(GL_TRIANGLE_FAN, 0, segments);
            
        }

        // dice zone
        {
            int segments = 20;
            GLfloat vertices[segments*3];
            int count=0;
            for (GLfloat i = 0; i < 360.0f; i+=(360.0f/segments))
            {
                vertices[count++] = x + (cos(DegreesToRadians(i))*DICE_RADIUS);
                vertices[count++] = y + (sin(DegreesToRadians(i))*DICE_RADIUS);
                vertices[count++] = 0;
            }
            glVertexAttribPointer (self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
            glDrawArrays(GL_LINE_LOOP, 0, segments);
            
        }
        
        // move vector
        CGFloat vertices[6];
        vertices[0] = x;
        vertices[1] = y;
        vertices[2] = 0;
        vertices[3] = x + Vx;
        vertices[4] = y + Vy;
        vertices[5] = 0;
        glVertexAttribPointer (self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
        glDrawArrays(GL_LINES, 0, 2);
        
        // reflection
        if(!isnan(reflection.x))
        {
            CGFloat vertices[6];
            vertices[0] = lastHitPoint.x;
            vertices[1] = lastHitPoint.y;
            vertices[2] = 0;
            vertices[3] = lastHitPoint.x + reflection.x;
            vertices[4] = lastHitPoint.y + reflection.y;
            vertices[5] = 0;
            glVertexAttribPointer (self.cubeShader.aPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
            glDrawArrays(GL_LINES, 0, 2);
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
    
    throwStartTime = CACurrentMediaTime();
    NSLog(@"Dice throw: %g:%g time: %g", x0, y0, time);
}

-(void) moveDice:(CGSize)delta
{
    // translate to scene coords
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    float dx = delta.width/self.bounds.size.width*PV_WIDTH*SHIFT_Z/NEAR;
    float dy = -delta.height/self.bounds.size.height*PV_HEIGTH*SHIFT_Z/NEAR;
    
    CGPoint hitPoint = [self testMarblesHit:1 withVx:dx withVy:dy];
    if(!isnan(hitPoint.x))
    {
        x = hitPoint.x;
        y = hitPoint.y;
        lastHitPoint = hitPoint;
        
        if(dice_locked)
        {
            [self throwDice:0.1 withX0:DICE_TO_MARBLE_MANUAL_HIT_MULTILIFIER*dx withY0:DICE_TO_MARBLE_MANUAL_HIT_MULTILIFIER*dy];
            dice_locked = NO;
        }

    }
    else
    {
        x += dx;
        y += dy;
    }
}

-(void) moveDiceTo:(CGPoint)pos
{
    // translate to scene coords
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    x = (pos.x - self.bounds.size.width/2)/self.bounds.size.width*PV_WIDTH*SHIFT_Z/NEAR;
    y = -(pos.y - self.bounds.size.height/2)/self.bounds.size.height*PV_HEIGTH*SHIFT_Z/NEAR;
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
    posInScene.x = (pos.x - self.bounds.size.width/2)/self.bounds.size.width*PV_WIDTH*SHIFT_Z/NEAR;
    posInScene.y = -(pos.y - self.bounds.size.height/2)/self.bounds.size.height*PV_HEIGTH*SHIFT_Z/NEAR;
    float distance = sqrtf(powf(posInScene.x - x, 2) + powf(posInScene.y - y, 2));
    //NSLog(@"Touch distance: %g", distance);
    return distance < 1.4;
}

-(void) setMarblesCoords:(CGPoint [])marbles andCount:(int)count withRadius:(float)radius
{
    marblesCount = MIN(count, MAX_MARBLES);
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    marbleRadius = radius/self.bounds.size.width*PV_WIDTH*SHIFT_Z/NEAR;
    float r = marbleRadius + DICE_RADIUS;
    for (unsigned int i = 0; i < marblesCount; ++i) {
        // translate to scene coords
        CGPoint pos = marbles[i];
        float mx = (pos.x - self.bounds.size.width/2)/self.bounds.size.width*PV_WIDTH*SHIFT_Z/NEAR;
        float my = -(pos.y - self.frame.origin.y - self.bounds.size.height/2)/self.bounds.size.height*PV_HEIGTH*SHIFT_Z/NEAR;
        marblesCoords[i] = CGPointMake(mx, my);
        //NSLog(@"Marble coord: [%g, %g]", mx, my);
        
        // test dice hit
        float distance2 = (mx-x)*(mx-x) + (my-y)*(my-y);
        float distance = sqrt(distance2);
        float dx = 0, dy = 0;
        if(distance2 < r*r)
        {
            if(distance == 0){
                dx = -r;
                dy = 0;
            }
            else{
                dx = r*(x-mx)/distance + mx - x;
                dy = r*(y-my)/distance + my - y;
            }
            x += dx;
            y += dy;
            [self throwDice:0.1 withX0:DICE_TO_MARBLE_MANUAL_HIT_MULTILIFIER*dx withY0:DICE_TO_MARBLE_MANUAL_HIT_MULTILIFIER*dy];
        }
    }
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
