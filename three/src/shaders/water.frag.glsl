uniform float uTime;
uniform vec3 uDeepColor;   // 深海の暗さ
uniform vec3 uLightColor;  // 上から差し込む光の色
uniform float uHeight;     // 水槽の高さ(縦グラデの正規化用)

varying vec2 vUv;
varying vec3 vWorldPos;

// 安価な擬似ノイズ
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  // 上(明るい)→下(暗い)への縦グラデーション
  float h = clamp(vWorldPos.y / uHeight + 0.5, 0.0, 1.0);
  float gradient = pow(h, 1.6);

  vec3 color = mix(uDeepColor, uLightColor, gradient);

  // ゴッドレイ風の光の筋: x方向に周期的な明暗、ゆっくり流れる
  float ray = sin(vWorldPos.x * 0.45 + uTime * 0.15)
            * sin(vWorldPos.x * 0.17 - uTime * 0.08);
  ray = smoothstep(0.2, 1.0, ray) * gradient * 0.35;
  color += uLightColor * ray;

  // 水の揺らぎ(微弱な明滅)
  float shimmer = sin(vUv.y * 30.0 + uTime * 0.6) * 0.015;
  color += shimmer;

  // 上方ほど不透明感を弱め、奥行きを感じさせる
  float alpha = mix(0.92, 0.6, gradient);

  gl_FragColor = vec4(color, alpha);
}
