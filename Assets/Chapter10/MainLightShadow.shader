//主光源阴影
Shader "URP/MainLightShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _Gloss("gloss",Range(10,300)) = 20
        _SpecularColor("SpecularColor",Color)= (1,1,1,1)
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
        half _Gloss;
        real4 _SpecularColor;
        CBUFFER_END

        //纹理采样
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float2 texcoord : TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord : TEXCOORD;
            float3 positionWS : TEXCOORD1;
            float3 normalWS : NORMAL;
        };

        ENDHLSL

        Pass
        {
            Tags{"LightMode"="UniversalForward"}
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma multi_compile _ _SHADOWS_SOFT

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //计算纹理坐标
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);

                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);

                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                //采样纹理
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);

                Light myLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                real4 lightColor = real4(myLight.color,1);
                float3 WS_L = normalize(myLight.direction);
                float3 WS_N = normalize(i.normalWS);
                float3 WS_V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 WS_H = normalize(WS_V + WS_L);

                float4 diffuse = (dot(WS_L,WS_N)*0.5+0.5) * myLight.shadowAttenuation * lightColor * texColor;

                float4 specular = pow(max(dot(WS_N,WS_H),0),_Gloss) * _SpecularColor * myLight.shadowAttenuation;

                return diffuse + specular;
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
