import {vec2, mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {

  color: vec4;
  fire: vec4;
  tips: vec4;
  turb: GLfloat;
  size: GLfloat;

  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setCubeColor(color: number[]) {
    this.color = vec4.fromValues(color[0]/255, color[1]/255, color[2]/255, 1);
  }

  setTurbulence(turb: number) {
    this.turb = turb;
  }

  setFireSize(size: number) {
    this.size = size;
  }

  setFireColors(fire: number[], tips: number[]) {
    this.fire = vec4.fromValues(fire[0]/255, fire[1]/255, fire[2]/255, 1.);
    this.tips = vec4.fromValues(tips[0]/255, tips[1]/255, tips[2]/255, 1.);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, time: number) {
    let model = mat4.create();
    let viewProj = mat4.create();

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(this.color);
    prog.setFireColor(this.fire);
    prog.setTurbulence(this.turb);
    prog.setSize(this.size);
    prog.setTipColor(this.tips);
    prog.setTime(time);
    prog.setResolution(vec2.fromValues(this.canvas.width, this.canvas.height));
    prog.setCamera(camera.controls.eye);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
