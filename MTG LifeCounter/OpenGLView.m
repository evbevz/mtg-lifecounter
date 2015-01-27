//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by Ray Wenderlich on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

@implementation OpenGLView

typedef struct {
    float Position[3];
    float TexCoord[2]; // New
} Vertex;

/*const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}
};
 
const GLubyte Indices[] = {
     0, 1, 2,
     2, 3, 0
};*/

// Add texture coordinates to Vertices as follows
#define EDGE 64.0/512

const Vertex Vertices[] = {
    // Front - 6
    {{1, -1, 1}, {EDGE, 0}},
    {{1, 1, 1},  {EDGE, EDGE}},
    {{-1, 1, 1}, {0, EDGE}},
    {{-1, -1, 1}, {0, 0}},
    // Back - 1
    {{1, 1, -1}, {EDGE, EDGE*5}},
    {{-1, -1, -1}, {0, EDGE*6}},
    {{1, -1, -1}, {EDGE, EDGE*6}},
    {{-1, 1, -1}, {0, EDGE*5}},
    // Left - 2
    {{-1, -1, 1}, {0, EDGE*5}},
    {{-1, 1, 1}, {0, EDGE*4}},
    {{-1, 1, -1}, {EDGE, EDGE*4}},
    {{-1, -1, -1}, {EDGE, EDGE*5}},
    // Right - 5
    {{1, -1, -1}, {EDGE, EDGE*2}},
    {{1, 1, -1}, {EDGE, EDGE}},
    {{1, 1, 1}, {0, EDGE}},
    {{1, -1, 1}, {0, EDGE*2}},
    // Top - 4
    {{1, 1, 1}, {0, EDGE*2}},
    {{1, 1, -1}, {EDGE, EDGE*2}},
    {{-1, 1, -1}, {EDGE, EDGE*3}},
    {{-1, 1, 1}, {0, EDGE*3}},
    // Bottom - 3
    {{1, -1, -1}, {0, EDGE*3}},
    {{1, -1, 1}, {EDGE, EDGE*3}},
    {{-1, -1, 1}, {EDGE, EDGE*4}},
    {{-1, -1, -1}, {0, EDGE*4}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 5, 6,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
};

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {   
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (GLuint)setupTexture:(NSString *)fileName {    
    // 1
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, 
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);    
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);        
    return texName;    
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);        
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];    
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);    
}

- (void)setupFrameBuffer {    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);   
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);    
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];    
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)compileShaders {
    
    // 1
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    // 2
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    //_colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    //glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
  
    _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(programHandle, "Texture");

}

- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}

#define NEAR 40.0
#define FAR 60.0
#define PV_WIDTH 10.0
#define ACCELERATION -5
#define SHIFT_Z 57.0

- (void)render:(CADisplayLink*)displayLink {
    
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    // add projection
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    [projection populateFromFrustumLeft:-PV_WIDTH/2 andRight:PV_WIDTH/2 andBottom:-PV_HEIGTH/2 andTop:PV_HEIGTH/2 andNear:NEAR andFar:FAR];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    
    // move
    if(v && (dx0 != 0 || dy0 != 0))
    {
        float t = displayLink.timestamp - _throwStartTime;
        float S = V0 * t + ACCELERATION * t * t / 2;
        float k = sqrtf(S * S / (dx0 * dx0 + dy0 * dy0));
        x = X0 + k*dx0;
        y = Y0 + k*dy0;
        v = MAX(0, V0 + ACCELERATION * t);
    }
    [modelView populateFromTranslation:CC3VectorMake(x, y, -SHIFT_Z)];
    
    // test for field walls
    if(x + 1 > (SHIFT_Z-1)/NEAR*PV_WIDTH/2)
    {
        dx0 = -ABS(dx0);
        V0 = v;
        X0 = x;
        Y0 = y;
        _throwStartTime = displayLink.timestamp;
    }
    if(x - 1 < -(SHIFT_Z-1)/NEAR*PV_WIDTH/2)
    {
        dx0 = ABS(dx0);
        V0 = v;
        X0 = x;
        Y0 = y;
        _throwStartTime = displayLink.timestamp;
    }
    if(y + 1 > (SHIFT_Z-1)/NEAR*PV_HEIGTH/2)
    {
        dy0 = -ABS(dy0);
        V0 = v;
        X0 = x;
        Y0 = y;
        _throwStartTime = displayLink.timestamp;
    }
    if(y - 1 < -(SHIFT_Z-1)/NEAR*PV_HEIGTH/2)
    {
        dy0 = ABS(dy0);
        V0 = v;
        X0 = x;
        Y0 = y;
        _throwStartTime = displayLink.timestamp;
    }
    
    // add rotation
    _currentRotationX += displayLink.duration * 90;
    _currentRotationY += displayLink.duration * 30;
    _currentRotationZ += displayLink.duration * 10;
    [modelView rotateBy:CC3VectorMake(_currentRotationX, _currentRotationY, _currentRotationZ)];


    //glUniformMatrix4fv(_modelViewUniform, 1, 0, identity_matrix);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    // 1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    // 2
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glActiveTexture(GL_TEXTURE0); 
    glBindTexture(GL_TEXTURE_2D, _texture1);
    glUniform1i(_textureUniform, 0);
    
    // 3
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];    
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        [self setupLayer];        
        [self setupContext];    
        [self setupDepthBuffer];
        [self setupRenderBuffer];        
        [self setupFrameBuffer];     
        [self compileShaders];
        [self setupVBOs];
        [self setupDisplayLink]; // render in loop, not only in init 
    }
    _texture1 = [self setupTexture:@"dice.png"];
    _currentRotationX = _currentRotationY = _currentRotationZ = 0;
    dx0 = dy0 = V0 = x = y = v = X0 = Y0 = 0;
    return self;
}

- (void)dealloc
{
    _context = nil;
}

-(void) throwDice:(float)v0 withX0:(float)x0 withY0:(float)y0
{
    dx0 = x0;
    dy0 = y0;
    V0 = v0;
    v = v0;
    _throwStartTime = CACurrentMediaTime();
    NSLog(@"Dice throw: %g:%g velocity:%g", x0, y0, v0);
}

-(void) moveDice:(float)xpos withY:(float)ypos
{
    float PV_HEIGTH = PV_WIDTH * self.frame.size.height / self.frame.size.width;
    x = X0 = (xpos - self.bounds.size.width/2)/self.bounds.size.width*PV_WIDTH*FAR/NEAR;
    y = Y0 = -(ypos - self.bounds.size.height/2)/self.bounds.size.height*PV_HEIGTH*FAR/NEAR;
    V0 = v = 0;
    NSLog(@"Dice move: %g:%g", xpos, ypos);
}

@end
