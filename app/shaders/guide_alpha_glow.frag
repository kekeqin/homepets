#version 320 es

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform vec2 u_target_origin;
uniform vec2 u_target_size;
uniform vec2 u_image_size;
uniform vec4 u_source_rect;
uniform float u_outline_width;
uniform float u_softness;
uniform float u_progress;
uniform sampler2D u_texture;

out vec4 fragColor;

const float PI = 3.1415926535897932384626;

float alpha_at_local(vec2 local) {
  vec2 uv = local / u_target_size;
  if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
    return 0.0;
  }

  vec2 source = u_source_rect.xy + uv * u_source_rect.zw;
  vec2 texture_uv = source / u_image_size;
  #ifdef IMPELLER_TARGET_OPENGLES
  texture_uv.y = 1.0 - texture_uv.y;
  #endif
  return texture(u_texture, texture_uv).a;
}

float max_neighbor_alpha(vec2 local, float radius) {
  float value = 0.0;
  value = max(value, alpha_at_local(local + vec2(1.0, 0.0) * radius));
  value = max(value, alpha_at_local(local + vec2(-1.0, 0.0) * radius));
  value = max(value, alpha_at_local(local + vec2(0.0, 1.0) * radius));
  value = max(value, alpha_at_local(local + vec2(0.0, -1.0) * radius));
  value = max(value, alpha_at_local(local + vec2(0.70710678, 0.70710678) * radius));
  value = max(value, alpha_at_local(local + vec2(-0.70710678, 0.70710678) * radius));
  value = max(value, alpha_at_local(local + vec2(0.70710678, -0.70710678) * radius));
  value = max(value, alpha_at_local(local + vec2(-0.70710678, -0.70710678) * radius));
  value = max(value, alpha_at_local(local + vec2(0.92387953, 0.38268343) * radius));
  value = max(value, alpha_at_local(local + vec2(-0.92387953, 0.38268343) * radius));
  value = max(value, alpha_at_local(local + vec2(0.92387953, -0.38268343) * radius));
  value = max(value, alpha_at_local(local + vec2(-0.92387953, -0.38268343) * radius));
  value = max(value, alpha_at_local(local + vec2(0.38268343, 0.92387953) * radius));
  value = max(value, alpha_at_local(local + vec2(-0.38268343, 0.92387953) * radius));
  value = max(value, alpha_at_local(local + vec2(0.38268343, -0.92387953) * radius));
  value = max(value, alpha_at_local(local + vec2(-0.38268343, -0.92387953) * radius));
  return value;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 local = p - u_target_origin;
  float original_alpha = alpha_at_local(local);

  float width = max(u_outline_width, 1.0);
  float near_alpha = max_neighbor_alpha(local, width * 0.36);
  float mid_alpha = max_neighbor_alpha(local, width * 0.68);
  float far_alpha = max_neighbor_alpha(local, width);
  float expanded_alpha = max(max(near_alpha, mid_alpha * 0.78), far_alpha * 0.44);

  float outside_alpha = 1.0 - smoothstep(0.01, 0.20, original_alpha);
  float outline_alpha = expanded_alpha * outside_alpha;

  float soft = max(u_softness, 1.0);
  float distance_hint = max(
    max(near_alpha - original_alpha, 0.0),
    max(mid_alpha * 0.78 - far_alpha * 0.34, 0.0)
  );
  float feather = smoothstep(0.0, 1.0, distance_hint + outline_alpha * 0.34);
  float alpha = clamp(outline_alpha * mix(0.74, 1.0, feather), 0.0, 1.0);

  vec2 target_uv = clamp(local / u_target_size, vec2(0.0), vec2(1.0));
  vec2 from_center = target_uv - vec2(0.5);
  float radial = 1.0 - smoothstep(0.25, 0.88, length(from_center));
  float angle = atan(from_center.y, from_center.x);
  float sweep = 0.5 + 0.5 * cos(angle - (u_progress * PI * 2.0));
  float glint = smoothstep(0.90, 1.0, sweep) * alpha;

  vec3 warm = mix(vec3(1.0, 0.78, 0.22), vec3(1.0, 0.98, 0.72), radial);
  vec3 color = mix(warm, vec3(1.0), glint * 0.82);
  float glow_alpha = alpha * (0.48 + radial * 0.26) + glint * 0.30;

  fragColor = vec4(color * glow_alpha, glow_alpha);
}
