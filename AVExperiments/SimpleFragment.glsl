varying lowp vec4 DestinationColor;

varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;

void main(void) {
    
    gl_FragColor = texture2D(Texture, TexCoordOut);
    
//    lowp vec4 calculatedColor = texture2D(Texture, TexCoordOut);

    /*
    lowp vec2 shiftedCoord = vec2(1.0 - TexCoordOut.x, 1.0 - TexCoordOut.y);
    
    calculatedColor.r *= shiftedCoord.x;
    calculatedColor.g *= shiftedCoord.y;
    calculatedColor.b *= pow(shiftedCoord.x, shiftedCoord.y);
    gl_FragColor = calculatedColor;
     */  
    
//    lowp vec4 inverted = vec4(1.0 - calculatedColor.r, 1.0 - calculatedColor.g, 1.0 - calculatedColor.b, 1.0);
//    gl_FragColor = inverted;

    /*
    lowp vec4 swizzled = calculatedColor.zyxw;
    
    swizzled.x = pow(swizzled.y, 0.858348735);
    swizzled.y = pow(swizzled.z, 0.858348735);
    swizzled.z = pow(swizzled.z, 0.858348735);
//    swizzled.x += 0.124275738;
//    swizzled.y -= 0.249856835;
//    swizzled.z /= 0.35352353;
    swizzled.w = 0.858348735;
//    calculatedColor.wx = exp(swizzled.xy);
//    calculatedColor.yz = log2(swizzled.wx);
//    calculatedColor.yxw = sqrt(swizzled.zyx);
    gl_FragColor = swizzled;
//    gl_FragColor = DestinationColor * texture2D(Texture, TexCoordOut);
     */
}