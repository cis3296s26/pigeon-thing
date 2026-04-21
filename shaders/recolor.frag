#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform sampler2D uTexture;
uniform vec3 targetColor;
uniform float threshold;
uniform vec2 imageSize;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / imageSize;

    vec4 original = texture(uTexture, uv);

    // transparency
    if (original.a < 0.01) {
        fragColor = vec4(0.0);
        return;
    }

    float r = original.r;
    float g = original.g;
    float b = original.b;

    float maxDiff = max(abs(r - g), max(abs(r - b), abs(g - b)));

    float brightness = (r + g + b) / 3.0;

    if (maxDiff < threshold && brightness < 0.9) {
        fragColor = vec4(targetColor * original.rgb, original.a);
    } else {
        fragColor = original;
    }
}