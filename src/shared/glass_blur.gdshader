shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius = 2.5;
uniform float tint_strength = 0.30;

void fragment() {
    vec2 step_uv = SCREEN_PIXEL_SIZE * blur_radius;
    vec4 color = textureLod(screen_texture, SCREEN_UV, 0.0) * 0.20;
    color += textureLod(screen_texture, SCREEN_UV + vec2(step_uv.x, 0.0), 0.0) * 0.12;
    color += textureLod(screen_texture, SCREEN_UV - vec2(step_uv.x, 0.0), 0.0) * 0.12;
    color += textureLod(screen_texture, SCREEN_UV + vec2(0.0, step_uv.y), 0.0) * 0.12;
    color += textureLod(screen_texture, SCREEN_UV - vec2(0.0, step_uv.y), 0.0) * 0.12;
    color += textureLod(screen_texture, SCREEN_UV + step_uv, 0.0) * 0.08;
    color += textureLod(screen_texture, SCREEN_UV - step_uv, 0.0) * 0.08;
    color += textureLod(screen_texture, SCREEN_UV + vec2(step_uv.x, -step_uv.y), 0.0) * 0.08;
    color += textureLod(screen_texture, SCREEN_UV + vec2(-step_uv.x, step_uv.y), 0.0) * 0.08;
    COLOR = vec4(mix(color.rgb, vec3(0.06, 0.10, 0.18), tint_strength), 0.78);
}
