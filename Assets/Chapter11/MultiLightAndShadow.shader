//多光源阴影
Shader "URP/MultiLightAndShadow"
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

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
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
            float3 WS_N : NORMAL;
            float3 WS_V : TEXCOORD1;
            float3 WS_P : TEXCOORD2;
        };

        ENDHLSL

        Pass
        {
            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //计算主光源阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            //用来获取阴影坐标
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            //用来获取额外光源的阴影衰减
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

            //柔化阴影 得到软阴影
            #pragma multi_compile _ _SHADOWS_SOFT  

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);
                o.WS_N = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));
                o.WS_V = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(i.positionOS.xyz));
                o.WS_P = TransformObjectToWorld(i.positionOS.xyz);
                
                return o;
            }

            real4 frag(v2f i) : SV_TARGET
            {
                //阴影纹理坐标
                half4 shadowTexcoord = TransformWorldToShadowCoord(i.WS_P);

                //采样纹理
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord) * _BaseColor;

                Light myLight = GetMainLight(shadowTexcoord);
                float3 WS_Light = normalize(myLight.direction);
                float3 WS_Normal = i.WS_N;
                float3 WS_View = i.WS_V;
                float3 WS_H = normalize(WS_View + WS_Light);
                float3 WS_Pos = i.WS_P;

                //计算主光源
                float4 mainColor = (dot(WS_Light,WS_Normal)*0.5+0.5) * tex * float4(myLight.color,1) * myLight.shadowAttenuation;
 
                //计算额外光源
                real4 addColor = real4(0,0,0,1);
                int addLightsCount = GetAdditionalLightsCount();
                for(int i = 0;i < addLightsCount;i++)
                {
                    Light addLight = GetAdditionalLight(i,WS_Pos);
                    float3 WS_addLightDir = normalize(addLight.direction);
                    addColor += (dot(WS_Normal,WS_addLightDir)*0.5+0.5) * real4(addLight.color,1) * tex 
                    * addLight.distanceAttenuation * addLight.shadowAttenuation;
                }

                return mainColor + addColor;
            }

            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
