//
//  ViewController.m
//  MTG LifeCounter
//
//  Created by Mac on 05.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define CARD_ROTATE_DURATION    0.4

#define CardNumbersColor        [UIColor colorWithRed:228.0/255 green:178.0/255 blue:114.0/255 alpha:1]
#define CardNumbersBorderColor  [UIColor colorWithRed:57.0/255 green:34.0/255 blue:4.0/255 alpha:1]
#define POISON_PREFIX           @"Poison_"

#define MIN_SCALE               MIN(x_scale, y_scale)
#define MAX_SCALE               MAX(x_scale, y_scale)

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface ViewController () {
    GLuint      _program;
    GLKView     *glView;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

- (void)selectPlayer:(int)i;

@end

@implementation ViewController

@synthesize context = _context;
@synthesize effect = _effect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    y_scale = [UIScreen mainScreen].bounds.size.height / 1024;
	x_scale = [UIScreen mainScreen].bounds.size.width / 768;
    
    current_player = 0;
    
    UIImageView *main = [[UIImageView alloc] initWithFrame:self.view.frame];
    main.image = [UIImage imageNamed:@"Background.png"];
    glView = (GLKView*)self.view;
    self.view = main;
    [self.view setUserInteractionEnabled:true];
    
    
    //NSLog(@"Create CardView");
    card = [[CardView alloc] initWithFrame:self.view.frame];
    card.backgroundImage = [UIImage imageNamed:@"Field.png"];
    card.frame = CGRectMake(140.0 * x_scale, 110.0 * y_scale, card.backgroundImage.size.width * x_scale, card.backgroundImage.size.height * y_scale);
    card.margin = 2;
    card.font = [UIFont fontWithName:@"GaramondPremrPro-Smbd" size:70 * x_scale];
    card.linesColor = [UIColor clearColor];
    card.fontColor = CardNumbersColor;
    card.fontBorderColor = CardNumbersBorderColor;
    card.backgroundColor = [UIColor clearColor];
    [self.view addSubview:card];
    
    float bottomBaseLine = card.frame.origin.y + card.frame.size.height + ([UIScreen mainScreen].bounds.size.height - (card.frame.origin.y + card.frame.size.height)) / 2.3;
    
    // +20/-20
    UIImageView *btn20back = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Btn20Back.png"]];
    float width = btn20back.image.size.width * MAX_SCALE;
    float height = btn20back.image.size.height * MAX_SCALE;
    btn20back.frame = CGRectMake(card.frame.origin.x + card.frame.size.width/2 - width/2, bottomBaseLine - height/2, width, height);
    [self.view addSubview:btn20back];
    
    UIImage *img = [UIImage imageNamed:@"Btn-20.png"];
	btn20_dec = [UIButton buttonWithType:UIButtonTypeCustom];
    width = img.size.width * MAX_SCALE;
    height = img.size.height * MAX_SCALE;
    btn20_dec.frame = CGRectMake(card.frame.origin.x + card.frame.size.width/2 - width - 5.0*MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
	[btn20_dec setImage:img forState:UIControlStateNormal];
    [btn20_dec addTarget:self action:@selector(counterButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn20_dec];

    img = [UIImage imageNamed:@"Btn+20.png"];
	btn20_inc = [UIButton buttonWithType:UIButtonTypeCustom];
    btn20_inc.frame = CGRectMake(card.frame.origin.x + card.frame.size.width/2 + 5.0*MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
	[btn20_inc setImage:img forState:UIControlStateNormal];
    [btn20_inc addTarget:self action:@selector(counterButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn20_inc];

    // Poison
    poison_val = 0;
    poison_img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png",POISON_PREFIX,poison_val]]];
    width = poison_img.image.size.width * MAX_SCALE;
    height = poison_img.image.size.height * MAX_SCALE;
    poison_img.frame = CGRectMake(45.0 * x_scale, card.frame.origin.y + card.frame.size.height - poison_img.image.size.height * MAX_SCALE + 10 * MAX_SCALE, width, height);
    [self.view addSubview:poison_img];
    
    UIImageView *poison_btn_back = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PoisonBtnsBack.png"]];
    width = poison_btn_back.image.size.width * MAX_SCALE;
    height = poison_btn_back.image.size.height * MAX_SCALE;
    poison_btn_back.frame = CGRectMake(27.0 * x_scale, bottomBaseLine - height/2, width, height);
    [self.view addSubview:poison_btn_back];
    
    img = [UIImage imageNamed:@"PoisonBtn+.png"];
    poison_inc = [UIButton buttonWithType:UIButtonTypeCustom];
    width = img.size.width * MAX_SCALE;
    height = img.size.height * MAX_SCALE;
    poison_inc.frame = CGRectMake(poison_btn_back.frame.origin.x + poison_btn_back.frame.size.width/2 - 2.0 * MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
    [poison_inc setImage:img forState:UIControlStateNormal];
    [poison_inc setImage:[UIImage imageNamed:@"PoisonBtn+A.png"] forState:UIControlStateHighlighted];
    [poison_inc addTarget:self action:@selector(poisonButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:poison_inc];

    img = [UIImage imageNamed:@"PoisonBtn-.png"];
    poison_dec = [UIButton buttonWithType:UIButtonTypeCustom];
    poison_dec.frame = CGRectMake(poison_btn_back.frame.origin.x + poison_btn_back.frame.size.width/2 - width + 2.0 * MAX_SCALE, bottomBaseLine - height/2 + 1, width, height);
    [poison_dec setImage:img forState:UIControlStateNormal];
    [poison_dec setImage:[UIImage imageNamed:@"PoisonBtn-A.png"] forState:UIControlStateHighlighted];
    [poison_dec addTarget:self action:@selector(poisonButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:poison_dec];

    //bubbles
    float bubblesBase = card.frame.origin.x / 1.75;
    img = [UIImage imageNamed:@"Bubble.png"];
    width = img.size.width * MAX_SCALE;
    height = img.size.height * MAX_SCALE;
    float top = card.frame.origin.y;
    for(int i = 0; i < PLAYER_BUTTONS_CNT; ++i)
    {
        btn[i] = [UIButton buttonWithType:UIButtonTypeCustom];
        btn[i].frame = CGRectMake(bubblesBase - width/2, top, width, height);
        [btn[i] setImage:img forState:UIControlStateNormal];        
        [btn[i] addTarget:self action:@selector(playerButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        top += (card.frame.size.height - poison_img.frame.size.height*0.9)/PLAYER_BUTTONS_CNT;
        
        [self.view addSubview:btn[i]];
        
        players[i].poison = 0;
        players[i].life = 20;
    }
    

    // Dice GL
    glView.frame = CGRectMake(40, 40, 100, 100);
    [self.view addSubview:glView];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = glView;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.backgroundColor = [UIColor clearColor];
    
    [self setupGL];
    
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)playerButtonTouched:(UIButton*)button
{
    for (int i = 0; i < PLAYER_BUTTONS_CNT; ++i) {
        if (btn[i] == button) 
        {
            [self selectPlayer:i];
        }
    }
}

- (void)counterButtonTouched:(UIButton*)button
{
    if(button == btn20_dec && card.lifeBase >= 20)
    {
        card.lifeBase -= 20;
        players[current_player].life -= 20;
    }
    if(button == btn20_inc)
    {
        card.lifeBase += 20;
        players[current_player].life += 20;
    }
    [card setNeedsDisplay];
}

- (void)poisonButtonTouched:(UIButton*)button
{
    if(button == poison_inc && poison_val < 10)
    {
        poison_val++;
        [self showPoison];
    }
    
    if(button == poison_dec && poison_val > 0)
    {
        poison_val--;
        [self showPoison];
    }

    players[current_player].poison = poison_val;

}

- (void) showPoison
{
    poison_img.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%d.png", POISON_PREFIX, poison_val]];
}

- (void)flipCard:(int)toPlayer
{
	NSLog(@"showCardForButton");
    
    [UIView beginAnimations:@"animationId" context:nil];
    [UIView setAnimationDuration:CARD_ROTATE_DURATION];
    [UIView setAnimationDelegate:self];
    //[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                           forView:card cache:YES];
    //[button setImage:image forState:UIControlStateNormal];
	//[button setBackgroundImage:backImage forState:UIControlStateNormal];
    card.lifeBase = (players[toPlayer].life - 1) / 20 * 20;
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
- (void)selectPlayer:(int)i
{
    
    [self flipCard:i];
    current_player = i;
    poison_val = players[i].poison;
    [self showPoison];
    
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    //NSLog(@"update");
    float aspect = fabsf(glView.bounds.size.width / glView.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotation += self.timeSinceLastUpdate * 0.5f;
    
    [glView setNeedsDisplay];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //NSLog(@"drawRect");
    
    //glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_NORMAL, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


@end
