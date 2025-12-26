// LiquidGlassShaders.metal

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct ShadowCaster {
    float4 color;
    float2 center;
    float2 size;
    float2 offset;
    float radius;
    float cornerRadius;
};

struct Uniforms {
    float2 size;
    int shapeCount;
    int paramCount;
    int shadowCasterCount;
    float maxLayerIndex;
    float2 textureOffset;
    float2 uvScale;
};

constant int STRIDE_SHAPE = 8;
constant int STRIDE_PARAM = 32;

constant float gaussianWeights[5][5] = {
    {1, 4, 7, 4, 1},
    {4, 16, 26, 16, 4},
    {7, 26, 41, 26, 7},
    {4, 16, 26, 16, 4},
    {1, 4, 7, 4, 1}
};

half4 applyFrostBlur(texture2d<half> tex, sampler s, float2 uv, float2 size, float blurRadius) {
    if (blurRadius < 0.5) return tex.sample(s, uv);
    float2 off = blurRadius / size;
    half4 c = half4(0.0);
    float sum = 0.0;
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            float w = gaussianWeights[i+2][j+2] / 273.0;
            c += tex.sample(s, uv + float2(i, j) * off) * w;
            sum += w;
        }
    }
    return c / sum;
}

float sdfSquircle(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

half4 applyShadows(float2 pixelPos, half4 baseColor, device const ShadowCaster *casters, int count) {
    half3 finalColor = baseColor.rgb;
    for (int i = count - 1; i >= 0; i--) {
        device const ShadowCaster &caster = casters[i];
        if (caster.color.a < 0.001) continue;
        float2 shadowPos = pixelPos - (caster.center + caster.offset);
        float sd = sdfSquircle(shadowPos, caster.size * 0.5, caster.cornerRadius);
        float adjustedRadius = caster.radius * 0.8;
        float shadowAlpha = smoothstep(adjustedRadius, -adjustedRadius, sd);
        shadowAlpha *= caster.color.a * 0.4;
        finalColor = half3(caster.color.rgb) * half(shadowAlpha) + finalColor * half(1.0 - shadowAlpha);
    }
    return half4(finalColor, baseColor.a);
}

float smoothUnion(float d1, float d2, float k) {
    if (k <= 0.001) return min(d1, d2);
    float e = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - e * e * 0.25 / k;
}

float getDropHeight(float sd, float thickness, float domeStrength) {
    float width = max(thickness * 2.0, 1.0);
    float t = clamp(-sd / width, 0.0, 1.0);
    return sqrt(1.0 - pow(1.0 - t, max(0.1, domeStrength) * 2.0)) * thickness;
}

float getLayerSDF(float2 p, device const float *shapeData, int shapeCount, int layerIdx, float blendK) {
    float layerSD = 1e5;
    bool hasShapes = false;
    for (int i = 0; i < shapeCount; i++) {
        int sOffset = i * STRIDE_SHAPE;
        if (abs(shapeData[sOffset + 6] - float(layerIdx)) > 0.1) continue;
        float2 center = float2(shapeData[sOffset + 1], shapeData[sOffset + 2]);
        float2 dims = float2(shapeData[sOffset + 3], shapeData[sOffset + 4]);
        float rad = shapeData[sOffset + 5];
        float d = sdfSquircle(p - center, dims * 0.5, rad);
        if (!hasShapes) { layerSD = d; hasShapes = true; }
        else { layerSD = smoothUnion(layerSD, d, blendK); }
    }
    return layerSD;
}

half3 calculateGlow(float2 pixelPos, float2 center, float radius, float intensity, half3 color) {
    float dist = distance(pixelPos, center);
    return color * half(exp(-(dist * dist) / (radius * radius)) * intensity);
}

half4 sampleTextureFromSlots(
    int index,
    sampler s,
    float2 uv,
    texture2d<half> tex0,
    texture2d<half> tex1,
    texture2d<half> tex2,
    texture2d<half> tex3
) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return half4(0.0);
    }
    switch (index) {
        case 1: return tex1.sample(s, uv);
        case 2: return tex2.sample(s, uv);
        case 3: return tex3.sample(s, uv);
        default: return tex0.sample(s, uv);
    }
}

half4 sampleBackground(
    texture2d<half> tex0,
    texture2d<half> tex1,
    texture2d<half> tex2,
    texture2d<half> tex3,
    sampler s,
    float2 uv,
    float2 size,
    int texIndex,
    float blurRadius,
    device const ShadowCaster *casters,
    int casterCount,
    bool useShadows
) {
    if (texIndex == 0) {
        half4 c = applyFrostBlur(tex0, s, uv, size, blurRadius);
        if (useShadows) {
            c = applyShadows(uv * size, c, casters, casterCount);
        }
        return c;
    } else {
        return sampleTextureFromSlots(texIndex, s, uv, tex0, tex1, tex2, tex3);
    }
}

float2 calculateSampleUV(
    float2 p,
    int texIndex,
    float2 size,
    float2 texOffset,
    float2 uvScale,
    float2 layerOffset,
    float2 layerScale
) {
    if (texIndex == 0) {
        return texOffset + (p / size) * uvScale;
    } else {
        return layerOffset + (p / size) * layerScale;
    }
}

half4 liquidGlass(
    float2 pixelPos,
    float2 size,
    device const float *shapeData,
    int shapeCount,
    device const float *paramData,
    int paramCount,
    device const ShadowCaster *shadowCasters,
    int shadowCasterCount,
    float maxLayerIndex,
    float2 textureOffset,
    float2 uvScale,
    texture2d<half> tex0,
    texture2d<half> tex1,
    texture2d<half> tex2,
    texture2d<half> tex3
) {
    constexpr sampler s(filter::linear, mip_filter::linear, address::clamp_to_edge);
    
    half3 surfaceAdditions = half3(0.0);
    half glassMaterialAlpha = half(0.0);
    float transmittance = 1.0;
    
    float2 rayOffset = float2(0.0);
    float totalBlur = 0.0;
    float accumulatedAlpha = 0.0;
    
    int finalTextureIndex = 0;
    float2 finalLayerUVOffset = float2(0.0);
    float2 finalLayerUVScale = float2(1.0);
    float activeChroma = 0.0;

    int maxLayers = int(maxLayerIndex) + 1;
    
    half4 accumulatedBackground = half4(0.0);
    bool hasAccumulatedResult = false;

    for (int layerIdx = maxLayers - 1; layerIdx >= 0; layerIdx--) {
        int pOffset = layerIdx * STRIDE_PARAM;
        if (pOffset >= paramCount * STRIDE_PARAM) continue;

        float2 distortedPixelPos = pixelPos + rayOffset;
        float blendValue = paramData[pOffset + 11];
        float sd = getLayerSDF(distortedPixelPos, shapeData, shapeCount, layerIdx, blendValue);
        
        float alpha = 1.0 - smoothstep(-0.5, 0.5, sd);
        if (alpha < 0.001) continue;
        
        accumulatedAlpha = max(accumulatedAlpha, alpha);
        
        if (alpha > 0.5) {
            finalTextureIndex = int(paramData[pOffset + 26]);
            finalLayerUVOffset = float2(paramData[pOffset + 27], paramData[pOffset + 28]);
            finalLayerUVScale = float2(paramData[pOffset + 29], paramData[pOffset + 30]);
            activeChroma = paramData[pOffset + 9];
        }

        float thick = paramData[pOffset + 7];
        float dome = paramData[pOffset + 12];
        float rawIOR = paramData[pOffset + 8];
        float opticalPass = paramData[pOffset + 31];
        
        if (paramData[pOffset + 13] > 0.5) {
            float eps = 1.0;
            float h_c = getDropHeight(sd, thick, dome);
            float h_x = getDropHeight(getLayerSDF(distortedPixelPos + float2(eps, 0.0), shapeData, shapeCount, layerIdx, blendValue), thick, dome);
            float h_y = getDropHeight(getLayerSDF(distortedPixelPos + float2(0.0, eps), shapeData, shapeCount, layerIdx, blendValue), thick, dome);
            float3 visualNormal = normalize(float3(h_c - h_x, h_c - h_y, 1.0));
            float2 distortion = visualNormal.xy * rawIOR * (thick * 0.1);
            rayOffset -= distortion * alpha * size;
        }
        
        if (paramData[pOffset + 17] > 0.5) {
            float2 glowCenter = float2(paramData[pOffset + 18], paramData[pOffset + 19]);
            float glowRad = paramData[pOffset + 20];
            float glowInt = paramData[pOffset + 21];
            half3 glowCol = half3(paramData[pOffset + 22], paramData[pOffset + 23], paramData[pOffset + 24]);
            
            surfaceAdditions += calculateGlow(pixelPos, glowCenter, glowRad, glowInt, glowCol) * alpha;
            glassMaterialAlpha = max(glassMaterialAlpha, half(length(glowCol) * 0.5));
        }
        
        if (paramData[pOffset + 15] > 0.5) {
            half4 glassColor = half4(paramData[pOffset], paramData[pOffset+1], paramData[pOffset+2], paramData[pOffset+3]);
            float density = alpha * glassColor.a;
            
            surfaceAdditions += glassColor.rgb * half(density) * half(transmittance);
            
            glassMaterialAlpha = max(glassMaterialAlpha, half(density));
            transmittance *= (1.0 - density);
        }
        
        if (paramData[pOffset + 14] > 0.5) {
            float eps = 1.0;
            float h_c = getDropHeight(sd, thick, dome);
            float h_x = getDropHeight(getLayerSDF(distortedPixelPos + float2(eps, 0.0), shapeData, shapeCount, layerIdx, blendValue), thick, dome);
            float h_y = getDropHeight(getLayerSDF(distortedPixelPos + float2(0.0, eps), shapeData, shapeCount, layerIdx, blendValue), thick, dome);
            float3 visualNormal = normalize(float3(h_c - h_x, h_c - h_y, 1.0));
            float angleParam = paramData[pOffset+4];
            float intensityParam = paramData[pOffset+5];
            float whitenessParam = paramData[pOffset+6];
            float edgeFactor = pow(1.0 - max(0.0, visualNormal.z), 1.0);
            float angle = atan2(visualNormal.y, visualNormal.x) + angleParam;
            half3 rainbowColor = half3(0.5 + 0.5 * cos(angle), 0.5 + 0.5 * cos(angle + 2.094), 0.5 + 0.5 * cos(angle + 4.188));
            half3 pastelColor = mix(rainbowColor, half3(1.0), half(clamp(whitenessParam, 0.0, 1.0)));
            
            surfaceAdditions += pastelColor * half(edgeFactor * intensityParam) * smoothstep(thick * 0.5, -thick * 0.1, -sd) * alpha;
            
            glassMaterialAlpha = max(glassMaterialAlpha, half(edgeFactor * alpha));
        }
        
        if (paramData[pOffset + 16] > 0.5) {
            totalBlur += paramData[pOffset + 10] * alpha;
        }
        
        if (layerIdx >= 0 && opticalPass > 0.5 && alpha > 0.1) {
            float2 baseDistortedPos = pixelPos + rayOffset;
            float2 uvG = calculateSampleUV(baseDistortedPos, finalTextureIndex, size, textureOffset, uvScale, finalLayerUVOffset, finalLayerUVScale);
            
            half4 layerSample = sampleBackground(tex0, tex1, tex2, tex3, s, uvG, size, finalTextureIndex, totalBlur, shadowCasters, shadowCasterCount, finalTextureIndex == 0);
            
            if (!hasAccumulatedResult) {
                accumulatedBackground = layerSample;
                hasAccumulatedResult = true;
            } else {
                accumulatedBackground = mix(accumulatedBackground, layerSample, half(alpha));
            }
        }
    }

    if (accumulatedAlpha < 0.001) { return half4(0.0); }
    
    float2 baseDistortedPos = pixelPos + rayOffset;
    half4 bgSample;
    
    if (hasAccumulatedResult) {
        bgSample = accumulatedBackground;
    } else {
        if (activeChroma > 0.001) {
            float2 offsetR = rayOffset * (1.0 + activeChroma);
            float2 offsetB = rayOffset * (1.0 - activeChroma);
            
            float2 posR = pixelPos + offsetR;
            float2 posG = baseDistortedPos;
            float2 posB = pixelPos + offsetB;
            
            float2 uvR = calculateSampleUV(posR, finalTextureIndex, size, textureOffset, uvScale, finalLayerUVOffset, finalLayerUVScale);
            float2 uvG = calculateSampleUV(posG, finalTextureIndex, size, textureOffset, uvScale, finalLayerUVOffset, finalLayerUVScale);
            float2 uvB = calculateSampleUV(posB, finalTextureIndex, size, textureOffset, uvScale, finalLayerUVOffset, finalLayerUVScale);
            
            half4 sampleR = sampleBackground(tex0, tex1, tex2, tex3, s, uvR, size, finalTextureIndex, totalBlur, shadowCasters, shadowCasterCount, finalTextureIndex == 0);
            half4 sampleG = sampleBackground(tex0, tex1, tex2, tex3, s, uvG, size, finalTextureIndex, totalBlur, shadowCasters, shadowCasterCount, finalTextureIndex == 0);
            half4 sampleB = sampleBackground(tex0, tex1, tex2, tex3, s, uvB, size, finalTextureIndex, totalBlur, shadowCasters, shadowCasterCount, finalTextureIndex == 0);
            
            bgSample = half4(sampleR.r, sampleG.g, sampleB.b, sampleG.a);
        } else {
            float2 uvG = calculateSampleUV(baseDistortedPos, finalTextureIndex, size, textureOffset, uvScale, finalLayerUVOffset, finalLayerUVScale);
            bgSample = sampleBackground(tex0, tex1, tex2, tex3, s, uvG, size, finalTextureIndex, totalBlur, shadowCasters, shadowCasterCount, finalTextureIndex == 0);
        }
    }
    
    half3 refractedBG = bgSample.rgb * half(transmittance);
    half3 finalRGB = refractedBG + surfaceAdditions;
    
    half finalAlpha = bgSample.a + (1.0 - bgSample.a) * glassMaterialAlpha;
    finalAlpha *= half(accumulatedAlpha);
    
    return half4(finalRGB, finalAlpha);
}

vertex VertexOut vertexPassthrough(uint vertexID [[vertex_id]]) {
    float2 positions[6] = {
        float2(-1.0, -1.0), float2( 1.0, -1.0), float2(-1.0,  1.0),
        float2(-1.0,  1.0), float2( 1.0, -1.0), float2( 1.0,  1.0)
    };
    VertexOut v;
    v.position = float4(positions[vertexID], 0.0, 1.0);
    v.uv = positions[vertexID] * 0.5 + 0.5;
    return v;
}

fragment float4 liquidGlassFragment(
    VertexOut in [[stage_in]],
    constant Uniforms &u [[buffer(0)]],
    device const float* shapeData [[buffer(1)]],
    device const float* paramData [[buffer(2)]],
    device const ShadowCaster* shadowCasters [[buffer(3)]],
    texture2d<half> tex0 [[texture(0)]],
    texture2d<half> tex1 [[texture(1)]],
    texture2d<half> tex2 [[texture(2)]],
    texture2d<half> tex3 [[texture(3)]]
) {
    return float4(liquidGlass(in.position.xy, u.size, shapeData, int(u.shapeCount)/STRIDE_SHAPE, paramData, int(u.paramCount)/STRIDE_PARAM, shadowCasters, int(u.shadowCasterCount), u.maxLayerIndex, u.textureOffset, u.uvScale, tex0, tex1, tex2, tex3));
}
