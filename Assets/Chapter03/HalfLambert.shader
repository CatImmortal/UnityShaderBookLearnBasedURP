//半兰伯特光照模型
Shader "URP/HalfLambert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            float4 normalOS : NORMAL;
            float2 texcoord : TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord : TEXCOORD;
            float normalWS : TEXCOORD1;
        };

        ENDHLSL

        Pass
        {
            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //计算纹理坐标
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);

                //将法线从模型空间转换到世界空间
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz,true);

                return o;
            }

            half4 FRAG(v2f i) : SV_TARGET
            {
                //采样纹理
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord) * _BaseColor;

                //计算漫反射
                Light myLight = GetMainLight();
                real4 lightColor = real4(myLight.color,1);
                float3 lightDir = normalize(myLight.direction);
                float lightAten = saturate(dot(lightDir,i.normalWS));
                return tex  * lightColor * (lightAten *0.5 + 0.5);
            }

            ENDHLSL
        }
    }
}
