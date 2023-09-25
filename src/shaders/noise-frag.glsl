#version 300 es

//////////////

// Fragment shader for the wispy noise around the Will-o'-the-Wisps

//////////////

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform vec2 u_Resolution;
uniform vec4 u_CameraPos;

uniform mat4 u_Model;
uniform float u_Size;

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform vec4 u_FireCol;
uniform vec4 u_TipCol; // core color

uniform float u_Turbulence;

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


///////////////////////////////////////////

// Simplex Noise shader references from https://www.shadertoy.com/view/NtBXWV

// No changes were made to the following 2 functions from shadertoy 
vec3 hash33(vec3 p3)
{
	vec3 MOD3 = vec3(.1031, .11369, .13787);
	p3 = fract(p3* MOD3);
	p3 += dot(p3, p3.yxz + 19.19);
	return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x + p3.z)*p3.y, (p3.y + p3.z)*p3.x));
}

float simplex_noise(vec3 p)
{
	const float K1 = 0.3333333;
	const float K2 = 0.1666667;

	vec3 i = floor(p + (p.x + p.y + p.z) * K1);
	vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);

	vec3 e = step(vec3(0, 0, 0), d0 - d0.yzx);
	vec3 i1 = e * (1.0 - e.zxy);
	vec3 i2 = 1.0 - e.zxy * (1.0 - e);

	vec3 d1 = d0 - (i1 - 1.0 * K2);
	vec3 d2 = d0 - (i2 - 2.0 * K2);
	vec3 d3 = d0 - (1.0 - 3.0 * K2);

	vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
	vec4 n = h * h * h * h * h * vec4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));

	return dot(vec4(31.316, 31.316, 31.316, 31.316), n);
}

// changes made to bring shadertoy shader into webGL
float render(vec2 uv)
{
    vec3 rd = 0.9 * vec3(uv, 0.);
    rd.y *= 0.8;

    // shape the wispy noise to have fire-like teardrop structure
    rd.y *= 9. * gain(rd.y + 0.5, 0.2) * u_Size;

    // need a few different time metrics oops
    float ti = u_Time * 0.15;
    float time = u_Time * 0.05;
    float t = pow(time+0.5,5.)*0.001 + 3.;

    rd.x += bias(rd.y + 1., 0.9) * 0.1 *  sin(rd.y * u_Turbulence - ti) * perlinNoise3D(fs_Pos.xyz);
    rd.y += bias(rd.y + 1., 0.9) * 0.1 * cos(rd.y * u_Turbulence - ti) * perlinNoise3D(fs_Pos.xyz);

    float n2 = simplex_noise((rd*t+t) * (1. / length(rd*t+rd)));
    
    n2 = simplex_noise((rd*t+t) * (1. / length(rd*t+rd))+(time-1.5));
    float flare = smoothstep(0.,1.,0.002 / length(rd*length(rd)*n2));
    
    return flare;
}

//////////////////////////////////////////////


void main()
{
    
    // use for subtle background cell-shading to produce glowy and wispy effects
    float dist = acos(dot(normalize(fs_Nor.xyz), normalize(u_CameraPos.xyz))) / (14. * 3.14159);

    // use look vector to apply wispy shader to area directly behind the wisp
    vec4 temp = vec4(0.0, 0.0, 1.0, 1.0) * u_ViewProj;
    vec3 lookVec = normalize(temp.xyz);
    vec3 rayOrigin = fs_Nor.xyz - lookVec;

    // bobble with wisp
    rayOrigin.y -= 0.0;
    rayOrigin.y -= 0.05 * cos(u_Time * 0.09);


    vec3 col = mix(u_Color.xyz, u_TipCol.xyz, 0.1 * length(fs_Pos.xy));
    col *= render(rayOrigin.xy);

    vec4 diffuseColor = vec4(col,1.0);
 
    // glowy effect using dist 
    dist = smootherstep(0., dist, 0.039);
    diffuseColor = mix(diffuseColor, vec4(0.,0.,0.,1.), dist + 0.05);

    diffuseColor = mix(diffuseColor, u_TipCol, 0.4 - length(rayOrigin));

    out_Col = diffuseColor;

}