#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Subtle Edge Distortion Shader
// Enhancement-only: Applied via SwiftUI .layerEffect
// Produces a very subtle refraction near edges of the glass surface,
// simulating light bending through thick glass.

[[ stitchable ]] half4 glassDistortion(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float intensity
) {
    // Normalise position to 0…1
    float2 uv = position / size;

    // Distance from center (0 at center, ~0.707 at corner)
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;
    float dist = length(delta);

    // Edge mask: strongest near edges, zero at center
    // Smooth step from 0.3 (no distortion) to 0.5 (full edge)
    float edgeMask = smoothstep(0.25, 0.55, dist);

    // Very subtle sinusoidal ripple — simulates glass refraction
    float ripple = sin(dist * 18.0 + time * 0.6) * 0.0012 * intensity;

    // Chromatic-style offset along the radial direction
    float2 offset = normalize(delta + 0.0001) * ripple * edgeMask;

    // Sample with offset (in pixel space)
    float2 distortedPos = position + offset * size;

    return layer.sample(distortedPos);
}

// MARK: - Subtle Chromatic Edge Effect
// Very light chromatic separation at extreme edges only.
[[ stitchable ]] half4 glassChromaticEdge(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float intensity
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 delta = uv - center;
    float dist = length(delta);

    // Only activate at the very edges
    float edgeMask = smoothstep(0.4, 0.6, dist) * intensity;

    float2 dir = normalize(delta + 0.0001);
    float shift = edgeMask * 0.4; // sub-pixel shift

    half4 colR = layer.sample(position + dir * shift);
    half4 colG = layer.sample(position);
    half4 colB = layer.sample(position - dir * shift);

    return half4(colR.r, colG.g, colB.b, colG.a);
}
