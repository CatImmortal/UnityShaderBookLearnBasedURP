//布林冯高光半兰伯特光照模型
Shader "URP/BlinnPhongHalfLambert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _SpecularRange("SpecularRange",Range(10,300)) = 10
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
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
        float _SpecularRange;
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
            float3 normalWS : NORMAL;
            float3 viewDirWS : TEXCOORD0;
            float2 texcoord : TEXCOORD1;
        };

        ENDHLSL

        Pass
        {
            NAME"MainPss"

            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #pragma vertex vert1
            #pragma fragment frag1

            v2f vert1(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //将法线从模型空间转换到世界空间
                o.normalWS = TransformObjectToWorldNormal(i.normalOS,true);

                //计算视角方向
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);

                //计算纹理坐标
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);

               

                return o;
            }

            half4 frag1(v2f i) : SV_TARGET
            {
                //采样纹理
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord) * _BaseColor;

                Light myLight = GetMainLight();
                
                //计算高光
                float3 lightDirWS = normalize(myLight.direction);
                float spe = saturate(dot(normalize(lightDirWS + i.viewDirWS),i.normalWS));
                real4 speColor = pow(spe,_SpecularRange) * _SpecularColor;

                //计算漫反射
                real4 lightColor = real4(myLight.color,1);
                float3 lightDir = normalize(myLight.direction);
                float lightAten = saturate(dot(lightDir,i.normalWS)) * 0.5 + 0.5;

                real4 texColor = lightAten * tex * _BaseColor;
                texColor *= real4(myLight.color,1);

                return speColor + texColor;
                
            }

            ENDHLSL
        }
    }
}
