Shader "Hidden/DeferredAO"
{
    Properties
    {
        _MainTex("-", 2D) = "" {}
        _OccTex("-", 2D) = "" {}
    }
    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float2 _MainTex_TexelSize;

    sampler2D _OccTex;

    float _Radius;
    float _Intensity;
    float _FallOff;

    // Camera projection matrix
    // Note: UNITY_MATRIX_P doesn't work with pixel shaders.
    float4x4 _Projection;

	sampler2D_float _CameraDepthTexture;
    sampler2D _CameraGBufferTexture2;

    const int SAMPLE_COUNT = 24;

    float nrand(float2 uv, float dx, float dy)
    {
        uv += float2(dx, dy + _Time.x);
        return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
    }

    float3 spherical_kernel(float2 uv, float index)
    {
        // Uniformaly distributed points
        // http://mathworld.wolfram.com/SpherePointPicking.html
        float u = nrand(uv, 0, index) * 2 - 1;
        float theta = nrand(uv, 1, index) * UNITY_PI * 2;
        float u2 = sqrt(1 - u * u);
        float3 v = float3(u2 * cos(theta), u2 * sin(theta), u);
        // Adjustment for distance distribution.
        float l = index / SAMPLE_COUNT;
        return v * lerp(0.1, 1.0, l * l);
    }

    half frag_ao(v2f_img i) : SV_Target 
    {
        // Sample a linear depth on the depth buffer.
        float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
        depth_o = LinearEyeDepth(depth_o);
        if (depth_o > _FallOff) return 0;

        // Sample a view-space normal vector on the g-buffer.
        float3 norm_o = tex2D(_CameraGBufferTexture2, i.uv).xyz * 2 - 1;
        norm_o = mul((float3x3)UNITY_MATRIX_V, norm_o);

        // Reconstruct the view-space position.
        float2 p11_22 = float2(_Projection._11, _Projection._22);
        float3 pos_o = float3((i.uv * 2 - 1) / p11_22, 1) * depth_o;

        float3x3 proj = (float3x3)_Projection;

        float occ = 0.0;
        for (int s = 0; s < SAMPLE_COUNT; s++)
        {
            float3 delta = spherical_kernel(i.uv, s);

            // Wants a sample in normal oriented hemisphere.
            delta *= (dot(norm_o, delta) >= 0) * 2 - 1;

            // Sampling point.
            float3 pos_s = pos_o + delta * _Radius;

            // Re-project the sampling point.
            float3 pos_sc = mul(proj, pos_s);
            float2 uv_s = (pos_sc.xy / pos_s.z + 1) * 0.5;

            // Sample a linear depth at the sampling point.
            float depth_s = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv_s));

            // Occlusion test.
            float dist = pos_s.z - depth_s;
            occ += (dist > 0.1) * (dist < _Radius);
        }

        float falloff = 1.0 - depth_o / _FallOff;
        return occ / SAMPLE_COUNT * _Intensity * falloff;
    }

    half4 frag_mul(v2f_img i) : SV_Target
    {
        half4 src = tex2D(_MainTex, i.uv);
        half occ = tex2D(_OccTex, i.uv).r;
        return half4(lerp(src.rgb, (half3)0, occ), src.a);
    }

    // Coefficients for the linear sampling Gaussian filter.
    // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
    static const float offset[3] = { 0.0, 1.3846153846, 3.2307692308 };
    static const float weight[3] = { 0.2270270270, 0.3162162162, 0.0702702703 };

    // Filter function of the separable Gaussian filter.
    float gaussian_filter(float2 uv, float2 stride)
    {
        float4 s = tex2D(_MainTex, uv).r * weight[0];
        for (int i = 1; i < 3; i++)
        {
            float2 d = stride * offset[i];
            s += tex2D(_MainTex, uv + d).r * weight[i];
            s += tex2D(_MainTex, uv - d).r * weight[i];
        }
        return s;
    }

    // Quarter downsampling.
    half frag_quarter(v2f_img i) : SV_Target
    {
        float4 s;
        s  = tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(-1, -1)).r;
        s += tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(+1, -1)).r;
        s += tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(-1, +1)).r;
        s += tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(+1, +1)).r;
        return s / 4;
    }

    // Separable Gaussian filter functions (horizontal/vertical).
    half frag_blur_h(v2f_img i) : SV_Target
    {
        return gaussian_filter(i.uv, float2(_MainTex_TexelSize.x, 0));
    }
    half frag_blur_v(v2f_img i) : SV_Target
    {
        return gaussian_filter(i.uv, float2(0, _MainTex_TexelSize.y));
    }

    ENDCG
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_ao
            ENDCG
        }
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_quarter
            ENDCG
        }
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_blur_h
            ENDCG
        }
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_blur_v
            ENDCG
        }
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_mul
            ENDCG
        }
    }
}
