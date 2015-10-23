//
//  PhongShader.m
//  GLBlender3
//
//  Created by bevz on 22/09/15.
//  Copyright © 2015 Ricardo Rendon Cepeda. All rights reserved.
//

#import "CubeShader.h"

#define STRINGIFY(A) #A
#include "Cube.fsh"
#include "Cube.vsh"

@implementation CubeShader

- (id)init
{
    if (self = [super init])
    {
        self.program = [self BuildProgram:PhongVSH with:PhongFSH];
        self.aPosition = glGetAttribLocation(self.program, "aPosition");
        self.aNormal = glGetAttribLocation(self.program, "aNormal");
        self.uProjectionMatrix = glGetUniformLocation(self.program, "uProjectionMatrix");
        self.uModelViewMatrix = glGetUniformLocation(self.program, "uModelViewMatrix");
        self.uNormalMatrix = glGetUniformLocation(self.program, "uNormalMatrix");
        self.uDiffuse = glGetUniformLocation(self.program, "uDiffuse");
        self.uSpecular = glGetUniformLocation(self.program, "uSpecular");
    }
    return self;
}

@end
