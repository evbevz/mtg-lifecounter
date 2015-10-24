
// fragment shader

static const char* PhongFSH = STRINGIFY
(

 varying highp vec3 vNormal;
 
 uniform highp vec3 uDiffuse;
 uniform highp vec3 uSpecular;
 
 void main(void)
 {
     highp vec3 ka = vec3(0.05);
     highp vec3 kd = uDiffuse;
     highp vec3 ks = uSpecular;
     highp float alpha = 1.0;
     
     highp vec3 ia = vec3(1.0);
     highp vec3 id = vec3(1.0);
     highp vec3 is = vec3(1.0);
     
     highp vec3 L = normalize(vec3(1.0,10.0,-10.0));
     highp vec3 N = normalize(vNormal);
     highp vec3 V = normalize(vec3(0.0, 0.0, 1.0));
     highp vec3 R = reflect(L, N);
     
     highp float df = max(0.0, dot(L, N));
     highp float sf = pow(max(0.0, dot(R, V)), alpha);
     
     highp vec3 Ip = ka*ia + kd*id*df + ks*is*sf;
     
     //highp vec3 material = (0.5 * uDiffuse) + (0.5 * uSpecular);
     gl_FragColor = vec4(Ip, 1.0);
 }
 
);
