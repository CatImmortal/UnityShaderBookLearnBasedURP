//渐变纹理
Shader "URP/RampMap"
{
    Properties
    {
        _MainTex ("Ramp", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"="Opaque" 
        }

        HLSLINCLUDE

        #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        CBUFFER_END

        //纹理采样
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;

        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS : NORMAL;
        };

        ENDHLSL

        Pass
        {
            Tags {
            "RenderPipeline" = "UniversalRenderPipeline"
            }


            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //计算世界法线
                o.normalWS = normalize(TransformObjectToWorldNormal(i.normalOS));

                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                real3 lightDir = normalize(GetMainLight().direction);

                float dott = dot(i.normalWS,lightDir) *0.5 +0.5;

                //在对渐变纹理采样时 不使用常规的模型uv 而是使用 Dot(N,L) v轴使用0.5
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,float2(dott,0.5));

                return texColor * _BaseColor;
            }

            ENDHLSL
        }
    }
}
