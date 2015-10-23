//
//  PhongShader.h
//  GLBlender3
//
//  Created by bevz on 22/09/15.
//  Copyright © 2015 Ricardo Rendon Cepeda. All rights reserved.
//

#import "Shader.h"

@interface CubeShader : Shader

@property (readwrite) GLint program;

@property (readwrite) GLint aPosition;
@property (readwrite) GLint aNormal;

@property (readwrite) GLint uProjectionMatrix;
@property (readwrite) GLint uModelViewMatrix;
@property (readwrite) GLint uNormalMatrix;
@property (readwrite) GLint uDiffuse;
@property (readwrite) GLint uSpecular;

@end
