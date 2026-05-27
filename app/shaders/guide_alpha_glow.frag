#version 320 es

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform vec2 u_target_origin;
uniform vec2 u_target_size;
uniform vec2 u_image_size;
uniform vec4 u_source_rect;
uniform float u_inner_width;
uniform float u_outer_width;
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

float sampled_mask(vec2 local, float radius) {
  return smoothstep(0.02, 0.34, max_neighbor_alpha(local, radius));
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 local = p - u_target_origin;
  float original_alpha = alpha_at_local(local);

  float inner_width = clamp(u_inner_width, 2.0, 10.0);
  float outer_width = max(u_outer_width, inner_width + 8.0);
  float softness = clamp(u_softness / outer_width, 0.25, 1.35);

  float outside_alpha = 1.0 - smoothstep(0.04, 0.34, original_alpha);

  float inner_near = max(
    sampled_mask(local, inner_width * 0.36),
    sampled_mask(local, inner_width * 0.70)
  );
  float inner_far = sampled_mask(local, inner_width);
  float inner_alpha = clamp(max(inner_near, inner_far) * outside_alpha, 0.0, 1.0);

  float gold_r1 = sampled_mask(local, inner_width + outer_width * 0.16);
  float gold_r2 = sampled_mask(local, inner_width + outer_width * 0.32);
  float gold_r3 = sampled_mask(local, inner_width + outer_width * 0.50);
  float gold_r4 = sampled_mask(local, inner_width + outer_width * 0.68);
  float gold_r5 = sampled_mask(local, inner_width + outer_width * 0.86);
  float gold_r6 = sampled_mask(local, inner_width + outer_width);
  float ring_index = 6.0;
  if (gold_r1 > 0.0) {
    ring_index = 1.0;
  } else if (gold_r2 > 0.0) {
    ring_index = 2.0;
  } else if (gold_r3 > 0.0) {
    ring_index = 3.0;
  } else if (gold_r4 > 0.0) {
    ring_index = 4.0;
  } else if (gold_r5 > 0.0) {
    ring_index = 5.0;
  }
  float halo_distance = clamp((ring_index - 1.0) / 5.0, 0.0, 1.0);
  float halo_mask = max(max(max(max(max(gold_r1, gold_r2), gold_r3), gold_r4), gold_r5), gold_r6);

  vec2 target_uv = clamp(local / u_target_size, vec2(0.0), vec2(1.0));
  vec2 from_center = target_uv - vec2(0.5);
  float angle = atan(from_center.y, from_center.x);
  float sweep = 0.5 + 0.5 * cos(angle - (u_progress * PI * 2.0));
  float glint = smoothstep(0.94, 1.0, sweep) * inner_alpha;

  float pulse = 0.90 + 0.08 * sin(u_progress * PI);
  float white_alpha = clamp((inner_alpha * 0.78 + glint * 0.08) * pulse, 0.0, 0.88);
  float gold_core_alpha = clamp(
    (inner_alpha * 0.18 + gold_r1 * 0.16 + gold_r2 * 0.10) *
      outside_alpha *
      pulse,
    0.0,
    0.38
  );
  float gold_soft_alpha = clamp(
    halo_mask *
      pow(1.0 - halo_distance, 1.85) *
      (0.34 + 0.14 * softness) *
      outside_alpha *
      pulse,
    0.0,
    0.34
  );

  float canvas_edge = min(min(p.x, p.y), min(u_size.x - p.x, u_size.y - p.y));
  float edge_fade = smoothstep(0.0, max(2.0, u_softness * 0.55), canvas_edge);

  vec3 white = vec3(1.0, 0.992, 0.941);
  vec3 gold_core = vec3(1.0, 0.878, 0.470);
  vec3 gold_soft = vec3(1.0, 0.839, 0.290);
  vec3 premul = white * white_alpha +
    gold_core * gold_core_alpha +
    gold_soft * gold_soft_alpha +
    white * glint * 0.10;
  float alpha = clamp(
    white_alpha + gold_core_alpha * 0.58 + gold_soft_alpha * 0.38,
    0.0,
    0.92
  );

  fragColor = vec4(premul * edge_fade, alpha * edge_fade);
}
