//
//  Shader.vsh
//  Quadz
//
//  Created by Dirk Zimmermann on 10/26/12.
//  Copyright (c) 2012 Dirk Zimmermann. All rights reserved.
//

uniform mat4 u_modelViewProjectionMatrix;

attribute vec4 a_position;
attribute vec4 a_color;
attribute vec2 a_texCoord0;

varying mediump vec4 v_color;
varying mediump vec2 v_texCoord0;

void main()
{
    gl_Position = u_modelViewProjectionMatrix * a_position;
    v_color = a_color;
    v_texCoord0 = a_texCoord0;
}
