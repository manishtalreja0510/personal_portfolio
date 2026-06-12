#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// The Big Bang flash: a blinding core that dies fast, plus an
// expanding shockwave ring with chromatic fringing (R/G/B sampled at
// slightly different radii). Drawn additively over the particle
// debris. uProgress is the Big Bang era's scroll progress (0..1), so
// scrolling backward runs the explosion in reverse.

uniform vec2 uSize;
uniform vec2 uCenter;
uniform float uProgress;
uniform float uTime;

out vec4 fragColor;

void main() {
  vec2 xy = FlutterFragCoord().xy;
  vec2 p = (xy - uCenter) / min(uSize.x, uSize.y);
  float d = length(p);

  // Core flash: huge at the first instant, collapsing quickly.
  float flash = exp(-d * mix(4.0, 18.0, uProgress)) * exp(-uProgress * 5.0) * 2.2;
  flash *= 0.97 + 0.03 * sin(uTime * 40.0); // faint plasma flicker

  // Shockwave radius matches the debris deceleration curve.
  float r = 1.3 * (1.0 - pow(1.0 - uProgress, 2.2));
  float wR = exp(-pow((d - r * 1.03) * 26.0, 2.0));
  float wG = exp(-pow((d - r) * 26.0, 2.0));
  float wB = exp(-pow((d - r * 0.97) * 26.0, 2.0));
  float ringAmp = 0.55 * exp(-uProgress * 2.5) * step(0.001, uProgress);

  vec3 col = flash * vec3(1.0, 0.96, 0.90);
  col += ringAmp * vec3(wR, wG, wB);

  // Warm ember tint near the center while the fireball is young.
  col += exp(-d * 6.0) * exp(-uProgress * 4.0) * vec3(0.40, 0.20, 0.05);

  // Additive light: color only, alpha untouched (paint uses plus).
  fragColor = vec4(col, 0.0);
}
