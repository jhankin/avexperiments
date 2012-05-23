uniform sampler2D SamplerY;
uniform sampler2D SamplerUV;
uniform highp vec4 Quaternion;
varying highp vec2 TexCoordOut;

mediump vec3 standardYUVForCoordinate(highp vec2 coord);

lowp vec3 hdRGBFromYUV(mediump vec3 yuv);
lowp vec3 sdRGBFromYUV(mediump vec3 yuv);
lowp vec3 grayscaleRGBFromYUV(mediump vec3 yuv);

void main(void)
{
    
    
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    highp float ratio;
    highp vec2 alteredCoord = TexCoordOut;

//    highp vec4 colorFromQuaternion = abs(Quaternion);
//    gl_FragColor = colorFromQuaternion;
    
    /*
//    highp vec2 alteredCoord = TexCoordOut - vec2(0.5, 0.5);

    lowp float xSign = sign(alteredCoord.x);
    lowp float ySign = sign(alteredCoord.y);
    
    highp float power = 2.0;
    
//    highp float numerator = (alteredCoord.x * alteredCoord.x) + (alteredCoord.y * alteredCoord.y);
    highp float numerator = pow(alteredCoord.x, power) + pow(alteredCoord.y, power);
    highp float denominator = pow(numerator, 1.0 / power);
//    highp float denominator = sqrt(numerator);
    ratio = numerator / denominator;
    
    alteredCoord = ratio * alteredCoord;
    */
    
    yuv = standardYUVForCoordinate(alteredCoord);
    rgb = hdRGBFromYUV(yuv);

    lowp vec3 combinedColor;
    combinedColor = abs(cross(rgb, Quaternion.xyz));
//    combinedColor = abs(rgb * Quaternion.xyz);
    
    gl_FragColor = vec4(combinedColor, 1);

}

mediump vec3 standardYUVForCoordinate(highp vec2 coord) {
    mediump vec3 yuv;
    yuv.x = texture2D(SamplerY, coord).r;
    yuv.yz = texture2D(SamplerUV, coord).rg - vec2(0.5, 0.5);
    return yuv;
}

lowp vec3 hdRGBFromYUV(mediump vec3 yuv) {
    lowp vec3 rgb = mat3(1,    1,       1,
                         0,   -.21482, 2.12798,
                         1.28033,     -.38059,       0) * yuv;
    return rgb;
}

lowp vec3 sdRGBFromYUV(mediump vec3 yuv) {
    lowp vec3 rgb = mat3(      1,       1,       1,
                             0, -.39465, 2.03211,
                             1.13983, -.58060,       0) * yuv;
    return rgb;
}

lowp vec3 grayscaleRGBFromYUV(mediump vec3 yuv) {
    lowp vec3 rgb;
    rgb.r = yuv.r;
    rgb.g = yuv.r;
    rgb.b = yuv.r;
    return rgb;
}




