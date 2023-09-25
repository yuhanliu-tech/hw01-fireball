#version 300 es

//////////////

// First attempt at making a fire shader! Stylized/toony fire effect with noise. 

//////////////

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;

uniform vec2 u_Resolution;

uniform float u_Turbulence;

uniform float u_Texture;

uniform float u_Size;

uniform float u_Lift;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 random3(vec3 p3) {
    vec3 p = fract(p3 * vec3(.4902,.199,.3929));
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


float noise3D(vec3 p) {
    return length(fract(sin(vec3(p.x * 1.27, p.y * 29.5, p.z * 1.312)) * 4.5));
}

float interpNoise3D(float x,float y, float z) {

    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = noise3D(vec3(intX, intY, intZ));
    float v2 = noise3D(vec3(intX + 1, intY, intZ));
    float v3 = noise3D(vec3(intX, intY + 1, intZ));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));

    float v5 = noise3D(vec3(intX, intY, intZ + 1));
    float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float zi1 = mix(i1, i3, fractZ);
    float zi2 = mix(i2, i4, fractZ);

    return mix(zi1, zi2, fractY);
}

float fbm(vec3 v, float freq, float amp) {
    float total = 0.0f;
    float persistence = 0.5f;
    int octaves = 8;

    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(v.x * freq, v.y * freq, v.z * freq) * amp;
        freq /= 100.f;
        amp *= persistence;
    }
    return total;
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

float triangle_wave(float x, float freq, float amplitude) {
    return abs(mod((x * freq), amplitude) - (0.5 * amplitude));
}

float sawtooth_wave(float x, float freq, float amplitude) {
    return (x * freq - floor(x * freq)) * amplitude; 
}

float smootherstep(float edge0, float edge1, float x) {
    x = clamp((x - edge0)/(edge1 - edge0), 0., 1.);
    return x * x * x *( x * (x * 6. - 15.) + 10.);
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation


    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    float t = u_Time * 0.05;

    // deform into tear shape 
    modelposition.x *= u_Size * gain(modelposition.y - 1., 0.19);
    modelposition.z *= u_Size * gain(modelposition.y - 1., 0.19);
    modelposition.y *= 1.45;

    // overall fire structure and movement
    modelposition.x += bias(modelposition.y + 1., 0.6) * sin(modelposition.y * u_Turbulence - t) * perlinNoise3D(modelposition.xyz);
    modelposition.z += bias(modelposition.y + 1., 0.6) * cos(modelposition.y * u_Turbulence - t) * perlinNoise3D(modelposition.xyz);

    // carry fire upwards more using sawtooth
    modelposition.y += (modelposition.y + 1.) * sawtooth_wave(modelposition.y - t * 0.1, u_Texture, 1.0) * perlinNoise3D(modelposition.xyz) * u_Lift;
    
    // smaller fire flares using high freq, low amp FBM
    modelposition.x += fbm(modelposition.xyz * -0.9, 10., 0.35);
    modelposition.z += fbm(modelposition.xyz * -0.9, 10., 0.35);

    // shift a bit
    modelposition.x -= 0.2;
    modelposition.z -= 0.3;
    modelposition.y -= 0.5;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
    fs_Pos = modelposition;

}
