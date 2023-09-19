import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  Tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  Color: [ 255, 0, 0],
  Fire: [255, 200, 0],
  Shadows: [40, 10, 10],
  Tips: [65, 13, 107],
  Turbulence: 5,
  Texture: 10,
  Size: 0.6,
  Lift: 0.7,
  'Reset':reset

};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;

let prevTesselations: number = 5;
let prevColor: number[] = controls.Color;
let time: number = 0;

let prevFire: number[] = controls.Fire;
let prevShadows: number[] = controls.Shadows;
let prevTips: number[] = controls.Tips;
let prevTurb: number = controls.Turbulence;
let prevSize: number = controls.Size;
let prevTexture: number = controls.Texture;
let prevLift: number = controls.Lift;

function reset() {
  controls.Tesselations = 5;
  controls.Color = [ 255, 0, 0];
  controls.Fire = [255, 200, 0];
  controls.Shadows = [40, 10, 10];
  controls.Tips = [65, 13, 107];
  controls.Turbulence = 5;
  controls.Texture = 10;
  controls.Size = 0.6;
  controls.Lift = 0.7;
}

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.Tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'Tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.addColor(controls, 'Color');
  gui.addColor(controls, 'Fire');
  gui.addColor(controls, 'Shadows');
  gui.addColor(controls, 'Tips');
  gui.add(controls, 'Turbulence', 0, 20).step(0.5);
  gui.add(controls, 'Size', 0.2, 0.8).step(0.1);
  gui.add(controls, 'Texture', 0, 50).step(1);
  gui.add(controls, 'Lift', 0, 1.5).step(0.1);
  gui.add(controls, 'Reset');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2', {alpha : true, premultipliedAlpha: false});

  
  gl.enable(gl.BLEND);
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  renderer.setCubeColor(controls.Color);
  renderer.setFireColors(controls.Fire, controls.Shadows, controls.Tips);
  renderer.setTurbulence(controls.Turbulence);
  renderer.setFireSize(controls.Size);
  renderer.setFireTexture(controls.Texture);
  renderer.setLift(controls.Lift)
  
  gl.enable(gl.SRC_ALPHA);
  gl.enable(gl.ONE_MINUS_SRC_ALPHA);
  gl.enable(gl.BLEND_SRC_ALPHA);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);
  
  const fire = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fire-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fire-frag.glsl')),
  ]);


  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.Tesselations != prevTesselations)
    {
      prevTesselations = controls.Tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    if(controls.Lift != prevLift)
    {
      prevLift = controls.Lift;
      renderer.setLift(controls.Lift);
    }

    if(controls.Size != prevSize)
    {
      prevSize = controls.Size;
      renderer.setFireSize(controls.Size);
    }

    if(controls.Texture != prevTexture)
    {
      prevTexture = controls.Texture;
      renderer.setFireTexture(controls.Texture);
    }

    if(controls.Turbulence != prevTurb)
    {
      prevTurb = controls.Turbulence;
      renderer.setTurbulence(controls.Turbulence);
    }

    if(controls.Color != prevColor)
    {
      prevColor = controls.Color;
      renderer.setCubeColor(controls.Color);
    }
    
    if(controls.Fire != prevFire || controls.Shadows != prevShadows || controls.Tips != prevTips)
    {
      prevFire = controls.Fire;
      prevShadows = controls.Shadows;
      prevTips = controls.Tips;
      renderer.setFireColors(controls.Fire, controls.Shadows, controls.Tips);
    }

    renderer.render(camera, fire, [
      icosphere,
    ], 
    time);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
    time++;
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
