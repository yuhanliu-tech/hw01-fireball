#version 300 es

/////////

// General fragment shader for the wisp 
// Essentially the same as wisp-frag-head but without the code to paint eyes

////////

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform vec2 u_Resolution;
uniform vec4 u_CameraPos;

uniform mat4 u_Model;

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform vec4 u_FireCol;
uniform vec4 u_ShadowCol;
uniform vec4 u_TipCol; // core color

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos; 

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float smootherstep(float edge0, float edge1, float x) {
    x = clamp((x - edge0)/(edge1 - edge0), 0., 1.);
    return x * x * x *( x * (x * 6. - 15.) + 10.);
}

void main()
{

    vec4 diffuseColor = u_Color;

    // smoother step improves color mixing between the three wisp colors
    // cell shading based on camera's look direction so that the wisp appears to have a glowing center

    float dist = acos(dot(normalize(fs_Nor.xyz), normalize(u_CameraPos.xyz))) / (1. * 3.14159);
    dist = smootherstep(0., dist, 0.1);
    diffuseColor = mix(diffuseColor, u_FireCol, dist);

    vec3 nor_adjusted = fs_Nor.xyz;
    nor_adjusted.y += 0.5;
    float smallerDist = acos(dot(normalize(nor_adjusted), normalize(u_CameraPos.xyz))) / (0.8 * 3.14159);
    smallerDist = smootherstep(0., smallerDist, 0.1);
    smallerDist *= 0.1 * cos(u_Time * 0.1) + 1.;
    diffuseColor = mix(diffuseColor, u_TipCol, smallerDist);
    
    out_Col = diffuseColor;

}