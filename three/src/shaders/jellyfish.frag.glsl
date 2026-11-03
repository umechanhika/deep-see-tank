uniform vec3 uColor;     // 個体ごとの基調色
uniform vec3 uRimColor;  // リムライトの色
uniform float uPulse;    // 脈動 0〜1
uniform float uOpacity;

varying vec3 vNormalW;
varying vec3 vViewDirW;
varying float vRim;
varying vec2 vUv;

void main() {
  // フレネルでリムを強調（半透明クラゲの縁取り）
  float fresnel = pow(vRim, 2.2);

  // 傘の頂点付近を明るく、裾に向け減衰
  float dome = smoothstep(0.0, 0.7, vUv.y);

  vec3 base = uColor * (0.35 + dome * 0.5);
  vec3 rim = uRimColor * fresnel * 1.6;

  // 脈動に合わせて内側から発光
  float glow = (0.4 + uPulse * 0.6) * dome;
  vec3 color = base + rim + uColor * glow * 0.7;

  // 縁ほど不透明、中央は透ける
  float alpha = clamp(uOpacity * (0.25 + fresnel * 0.9 + dome * 0.2), 0.0, 1.0);

  gl_FragColor = vec4(color, alpha);
}
