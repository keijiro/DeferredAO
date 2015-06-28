Shader "Hidden/DeferredAO"
{
    Properties
    {
        _MainTex("-", 2D) = "" {}
        _Params("-", Vector) = (1, 0.01, 1, 1)
    }
    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float2 _MainTex_TexelSize;

    float _Radius;
    float4 _Params; // x=radius, y=minz, z=attenuation power, w=SSAO power

	sampler2D_float _CameraDepthTexture;
    sampler2D _CameraGBufferTexture2;

    const int SAMPLE_COUNT = 8;

    float nrand(float2 uv, float dx, float dy)
    {
        uv += float2(dx, dy);
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

    half4 frag(v2f_img i) : SV_Target 
    {
        // Sample linear depth value.
        float depth_org = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
        if (depth_org > 0.9999) return (half4)1;
        depth_org = LinearEyeDepth(depth_org);

        // Sample normal vector in the view space.
        float3 norm_ws = tex2D(_CameraGBufferTexture2, i.uv).xyz * 2 - 1;
        float3 norm_vs = mul((float3x3)UNITY_MATRIX_V, norm_ws);

        // Scale factor for converting view space vector to UV offset.
        float2 delta_to_uv = float2(_ScreenParams.y / _ScreenParams.x, 1) * _Radius / depth_org;

        float occ = 0.0;
        for (int s = 0; s < SAMPLE_COUNT; s++)
        {
            float3 delta = spherical_kernel(i.uv, s);

            // Wants a sample in normal oriented hemisphere.
            delta *= (dot(norm_vs, delta) >= 0) * 2 - 1;

            float2 uv = i.uv + delta.xy * delta_to_uv;
            float depth = depth_org + (delta.z * _Radius);

            // Sample depth at offset location
            float depth_s = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));

            occ += (depth_s < depth) && (depth - depth_s < _Radius);
        }

        return 1.0 - occ / SAMPLE_COUNT;
    }

    ENDCG
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            ENDCG
        }
    }
}
