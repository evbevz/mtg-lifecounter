// Created with mtl2opengl.pl

/*
source files: .\FREE_CASINO_CUBE_OBJ-1.obj, .\FREE_CASINO_CUBE_OBJ.mtl
materials: 2

Name: Black_plastic
Ka: 0.000, 0.000, 0.000
Kd: 0.100, 0.100, 0.100
Ks: 1.000, 1.000, 1.000
Ns: 10.000

Name: Oro
Ka: 0.000, 0.000, 0.000
Kd: 0.000, 0.000, 0.000
Ks: 0.800, 0.600, 0.200
Ns: 10.000

*/


int CUBE_NumMaterials = 2;

int CUBE_First [2] = {
0,
10080,
};

int CUBE_Count [2] = {
10080,
18144,
};

float CUBE_Ambient [2][3] = {
0.000,0.000,0.000,
0.000,0.000,0.000,
};

float CUBE_Diffuse [2][3] = {
0.100,0.100,0.100,
0.000,0.000,0.000,
};

float CUBE_Specular [2][3] = {
1.000,1.000,1.000,
0.800,0.600,0.200,
};

float CUBE_Exponent [2] = {
10.000,
10.000,
};

