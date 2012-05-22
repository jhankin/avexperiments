uniform sampler2D SamplerY;
uniform sampler2D SamplerUV;

varying highp vec2 TexCoordOut;

void main(void)
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    yuv.x = texture2D(SamplerY, TexCoordOut).r;
    yuv.yz = texture2D(SamplerUV, TexCoordOut).rg - vec2(0.5, 0.5);

//    yuv.y = texture2D(SamplerY, TexCoordOut).r;
//    yuv.z = texture2D(SamplerY, TexCoordOut).r;

    
    // BT.601, which is the standard for SDTV is provided as a reference
//     rgb = mat3(      1,       1,       1,
//     0, -.39465, 2.03211,
//     1.13983, -.58060,       0) * yuv;
    
    // Using BT.709 which is the standard for HDTV
    rgb = mat3(1,    1,       1,
               0,   -.21482, 2.12798,
               1.28033,     -.38059,       0) * yuv;
    
    /*
    rgb = mat3(      1,       1,       1,
               0, .8462, 2.03211,
               .13983, .58060,       0) * yuv;
    */
    gl_FragColor = vec4(rgb, 1);
//    gl_FragColor = vec4(yuv, 1);

}
