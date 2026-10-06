import * as THREE from 'three';
import { slotPosition } from '../formation';
import type { PalSceneRecipe, Surface } from './palSceneRecipes';

const MODES: Surface[] = ['earth', 'tiles', 'wood', 'rock', 'roots', 'lava', 'red'];
/** 世界座標材質讓地板與真正 3D 道具共用空間；沒有投影 JPG 或天空盒。 */
export function palSurface(recipe: PalSceneRecipe) {
  const [x, , z] = slotPosition('enemy', 0, 1);
  return new THREE.ShaderMaterial({
    uniforms: {
      base: { value: new THREE.Color(recipe.ground) }, ink: { value: new THREE.Color(recipe.detail) },
      mode: { value: MODES.indexOf(recipe.surface) }, time: { value: 0 }, center: { value: new THREE.Vector2(x, z) },
      variant: { value: recipe.features.includes('波浪形岩壁') ? 1 : recipe.features.includes('褐色小徑') ? 2 : recipe.architecture === 'graves' ? 3 : 0 },
    },
    vertexShader: `varying vec2 p;
      void main(){ vec4 w=modelMatrix*vec4(position,1.);p=w.xz;gl_Position=projectionMatrix*viewMatrix*w; }`,
    fragmentShader: `uniform vec3 base,ink;uniform float mode,time,variant;uniform vec2 center;varying vec2 p;
      float hash(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
      float noise(vec2 q){vec2 i=floor(q),f=fract(q);f=f*f*(3.-2.*f);
        return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+1.),f.x),f.y);}
      vec2 cells(vec2 q){vec2 i=floor(q),f=fract(q);float a=9.,b=9.;
        for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
          vec2 v=vec2(float(x),float(y));vec2 jitter=vec2(hash(i+v),hash(i+v+19.));
          float d=length(v+jitter*.74+.13-f);if(d<a){b=a;a=d;}else b=min(b,d);}
        return vec2(a,b-a);}
      void main(){float grain=noise(p*64.);float n=noise(p*3.)*.65+noise(p*11.)*.35;
        vec3 c=mix(ink,base,.35+n*.85);float seam=0.;
        if(mode<.5){vec2 v=cells(p*3.);float stone=(1.-smoothstep(.12,.2,v.x))*smoothstep(2.7,4.8,length(p));
          c=mix(c,base*1.28,stone*.5);
          if(variant>1.5&&variant<2.5){float path=abs(p.x*.45+p.y*.8+.25*sin(p.y*1.4));
            c=mix(c,vec3(.16,.26,.105)*(.75+n*.55),smoothstep(.8,1.65,path));}
          if(variant>2.5){float edge=min(abs(p.x+4.6),abs(p.x-5.2));
            float slot=floor((p.y+2.58)/1.65+.5);float dz=abs(p.y-(-2.58+slot*1.65));
            if(slot>=0.&&slot<=3.&&edge<.295&&dz<.445)discard;}}
        if(mode>0.5&&mode<1.5){vec2 q=mat2(.707,-.707,.707,.707)*p*3.8;
          vec2 f=fract(q);float edge=min(min(f.x,1.-f.x),min(f.y,1.-f.y));
          seam=1.-smoothstep(.014,.035,edge);c=base*(.88+hash(floor(q))*.2);}
        if(mode>1.5&&mode<2.5){vec2 q=p*vec2(2.4,8.);float edge=min(fract(q.y),1.-fract(q.y));
          seam=(1.-smoothstep(.012,.05,edge))*.75;
          c=mix(ink,base,.6+.28*sin(p.x*61.+noise(p*5.)*9.)+.1*n);}
        if(mode>2.5&&mode<3.5){vec2 v=cells(p*4.);seam=1.-smoothstep(.015,.06,v.y);
          c=mix(ink,base,.55+.4*noise(p*8.));
          if(variant>.5&&variant<1.5){float folds=sin(p.x*4.+p.y*9.+noise(p*1.4)*9.);
            seam=pow(abs(folds),12.)*.5;c=mix(ink,base,.55+.24*folds+.16*n);}}
        if(mode>3.5&&mode<4.5){float root=abs(sin(p.x*24.+p.y*12.+noise(p*7.)*5.));
          float cross=abs(sin(p.x*14.-p.y*27.+noise(p*6.)*5.));
          c=mix(c,base*1.32,(1.-smoothstep(.08,.19,min(root,cross)))*.75);}
        if(mode>4.5&&mode<5.5){vec2 q=p-center;float r=length(q);float a=atan(q.y,q.x);
          float wave=sin(r*23.+a*2.+noise(q*3.)*3.-time*.6);
          float hot=1.-smoothstep(.55,1.85,r+.08*wave);
          c=mix(mix(ink,base,.7+.25*wave),vec3(1.,.88,.31)*(1.+.1*wave),hot);
          seam=(1.-smoothstep(.02,.11,cells(p*2.4).y))*smoothstep(2.2,3.6,r);}
        if(mode>5.5){c=mix(ink,base,.64+.18*sin(p.y*36.+noise(p*3.)*2.)+.1*n);}
        c=mix(c,ink,seam*.7);c*=.96+.08*grain;
        gl_FragColor=vec4(c,1.);
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
      }`,
  });
}
