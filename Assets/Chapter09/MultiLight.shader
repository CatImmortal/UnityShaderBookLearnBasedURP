//多光源处理
Shader "URP/MultiLight"
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
            float3 normalWS : NORMAL;
            float3 viewDirWS : TEXCOORD0;
            float3 positionWS : TEXCOORD1;
            float2 texcoord : TEXCOORD2;
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

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS);

                o.normalWS = TransformObjectToWorldNormal(i.normalOS);

                o.positionWS = TransformObjectToWorld(i.positionOS);

                o.viewDirWS = normalize(_WorldSpaceCameraPos - o.positionWS);

                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);

                return o;
            }

            real4 frag(v2f i) : SV_TARGET
            {
                //采样纹理
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);

                //计算主光源
                Light myLight = GetMainLight();
                real4 lightColor = real4(myLight.color,1);
                float3 lightDirWS = normalize(myLight.direction);
                float3 halfWS = normalize(i.viewDirWS + lightDirWS);
                float4 mainDiffuse = saturate(dot(lightDirWS,i.normalWS)) *0.5 + 0.5;
                mainDiffuse *= lightColor * texColor * _BaseColor;

                //计算多光源
                real4 addDiffuse = real4(0,0,0,1);

                //遍历所有额外灯光进行计算
                int addLightsCount = GetAdditionalLightsCount();
                for(int index = 0; index < addLightsCount;index++)
                {
                    Light addLight = GetAdditionalLight(index,i.positionWS);
                    real4 addColor = real4(addLight.color,1);
                    float3 addLightDirWS = normalize(addLight.direction);
                    
                    real4  tempAddDiffuse = saturate(dot(addLightDirWS,i.normalWS)) *0.5 + 0.5;
                    tempAddDiffuse *= addLight.distanceAttenuation * addLight.shadowAttenuation * addColor* texColor * _BaseColor;

                    //累加额外灯光的漫反射
                    addDiffuse += tempAddDiffuse;
                }

                return mainDiffuse + addDiffuse;

 
            }

            ENDHLSL
        }
    }
}
