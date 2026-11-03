uniform float uPulse; // 0.0〜1.0 の脈動

varying vec3 vNormalW;
varying vec3 vViewDirW;
varying float vRim;
varying vec2 vUv;

void main() {
  vUv = uv;

  // 傘の収縮: 中心から離れた頂点ほど脈動で下＋内へ絞り込む
  vec3 p = position;
  float radial = length(p.xz);
  float contract = uPulse * 0.35;
  p.xz *= 1.0 - contract * smoothstep(0.0, 1.0, radial);
  p.y -= uPulse * 0.25 * smoothstep(0.0, 1.2, radial);

  vec4 worldPos = modelMatrix * vec4(p, 1.0);
  vNormalW = normalize(mat3(modelMatrix) * normal);
  vViewDirW = normalize(cameraPosition - worldPos.xyz);
  vRim = 1.0 - max(dot(vNormalW, vViewDirW), 0.0);

  gl_Position = projectionMatrix * viewMatrix * worldPos;
}
