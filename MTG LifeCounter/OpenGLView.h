//
//  OpenGLView.h
//  HelloOpenGL
//
//  Created by Ray Wenderlich on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import "CC3GLMatrix.h"


@interface OpenGLView : UIView {
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
        
    GLuint _depthRenderBuffer;
    GLuint _texture1;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    float dx0, dy0, V0, X0, Y0;
    float v, x, y;
    CFTimeInterval _throwStartTime;
    
    CGPoint     dice_throw_start;
    CGPoint     dice_throw_end;
    double      dice_throw_time;
    double      dice_previous_move_time;
    Boolean     dice_locked;
    int         diceTouchCounter;
    
    CC3GLMatrix *savedRotation;

}

-(void) throwDice:(float)v0 withX0:(float)x0 withY0:(float)y0;
-(void) moveDice:(CGSize)delta;
-(BOOL) diceTouched:(CGPoint)pos;

@end
