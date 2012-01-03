//
//  Shader.fsh
//  MTG LifeCounter
//
//  Created by Mac on 05.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

varying lowp vec4 colorVarying;

varying lowp vec2 texCoordOut;
uniform sampler2D texture;

void main()
{
    gl_FragColor = colorVarying * texture2D(texture, texCoordOut);
    //gl_FragColor = colorVarying;

}
