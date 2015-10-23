
// vertex shader

static const char* PhongVSH = STRINGIFY
(

 attribute vec3 aNormal;
 attribute vec3 aPosition;
 
 uniform mat4 uProjectionMatrix;
 uniform mat4 uModelViewMatrix;
 uniform mat3 uNormalMatrix;
 
 varying vec3 vNormal;
 
 void main(void)
 {
    vNormal = uNormalMatrix * aNormal;
    gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aPosition, 1.0);
 }
 
);
