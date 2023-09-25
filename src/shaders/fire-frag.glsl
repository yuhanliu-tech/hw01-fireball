#version 300 es

//////////////

// First attempt at making a fire shader! Stylized/toony fire effect with noise. 

//////////////


precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform vec2 u_Resolution;

uniform vec4 u_FireCol;
uniform vec4 u_ShadowCol;
uniform vec4 u_TipCol;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos; 

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


vec3 random3(vec3 p3) {
    vec3 p = fract(p3 * vec3(.42,.19,.3029));
    p += dot(p, p.yxz + 19.89);
    return fract(vec3((p.x + p.y)*p.z, (p.x+p.z)*p.y, (p.y+p.z)*p.x));
}

float surflet3D(vec3 p, vec3 gridPoint) {

    float t2x = abs(p.x - gridPoint.x);
    float t2y = abs(p.y - gridPoint.y);
    float t2z = abs(p.z - gridPoint.z);

    float tx = 1.f - 6.f * pow(t2x, 5.f) + 15.f * pow(t2x, 4.f) - 10.f * pow(t2x, 3.f);
    float ty = 1.f - 6.f * pow(t2y, 5.f) + 15.f * pow(t2y, 4.f) - 10.f * pow(t2y, 3.f);
    float tz = 1.f - 6.f * pow(t2z, 5.f) + 15.f * pow(t2z, 4.f) - 10.f * pow(t2z, 3.f);

    vec3 gradient = random3(gridPoint) * 2.f - vec3(1.f);

    vec3 diff = p - gridPoint;

    float height = dot(diff, gradient);

    return height * tx * ty * tz;
}

float perlinNoise3D(vec3 p) {
    float surfletSum = 0.f;

    for (int dx = 0; dx <= 1; ++dx) {
        for (int dy = 0; dy <= 1; ++dy) {
            for (int dz = 0; dz <= 1; ++dz) {
                surfletSum += surflet3D(p, floor(p) + vec3(dx, dy, dz));
            }
        }
    }
    return surfletSum ;
}

float bias(float b, float t) {
    return pow(t, log(b) / log(0.5));
}

float gain(float g, float t) {
    if (t < 0.5) {
        return bias(1.-g, 2.*t) / 2.;
    } else {
        return 1. - bias(1.-g, 2.- 2.*t) / 2.;
    }
}

float smootherstep(float edge0, float edge1, float x) {
    x = clamp((x - edge0)/(edge1 - edge0), 0., 1.);
    return x * x * x *( x * (x * 6. - 15.) + 10.);
}

void main()
{
    vec4 diffuseColor = u_Color;

    // mix with secondary fire color
    diffuseColor = mix(u_FireCol, diffuseColor, clamp(perlinNoise3D(u_Time * 0.05 + fs_Pos.xyz),0.3,1.));
    
    // mix back with first fire color
    diffuseColor = mix(u_Color, diffuseColor, bias(length(fs_Pos.xz), 0.2));

    // mix with tertiary fire color (mostly concentrated at the tips)
    diffuseColor = mix(u_TipCol, diffuseColor, smoothstep(fs_Pos.y - 0.5, 1., 0.6));

    // add fire shadows to center
    diffuseColor = mix(u_ShadowCol, diffuseColor, bias(length(fs_Pos.xz), 0.4)); 

    out_Col = diffuseColor;


}