//法线贴图
Shader "URP/NormalMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        
        [Normal]
        _NormalTex("Normal",2D) = "bump"{}
        _NormalScale("NormalScale",Range(0,1)) = 1

        _SpecularRange("SpecularRange",Range(1,200)) = 50
        [HDR]
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        }

        HLSLINCLUDE

        #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _NormalTex_ST;
        real4 _BaseColor;
        real _NormalScale;
        real _SpecularRange;
        real4 _SpecularColor;
        CBUFFER_END

        //纹理采样
        TEXTURE2D(_MainTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_MainTex);
        SAMPLER(sampler_NormalTex);

        struct a2v
        {
            float4 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float4 tangentOS : TANGENT;  //顶点切线
            float2 texcoord : TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float4 normalWS : NORMAL;
            float4 tangentWS : TANGENT;
            float4 BtangentWS : TEXCOORD0;
            float4 texcoord : TEXCOORD1;
        };

        ENDHLSL

        Pass
        {
            NAME"MainPss"

            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //获取世界空间的法线 切线并标准化
                o.normalWS.xyz = normalize(TransformObjectToWorldNormal(i.normalOS));
                o.tangentWS.xyz = normalize(TransformObjectToWorldDir(i.tangentOS));

                //叉乘法线切线得到副切线 再乘切线的w值判断正负 再乘负奇数缩放影响因子
                //这里乘一个unity_WorldTransformParams.w是为判断是否使用了奇数相反的缩放
                o.BtangentWS.xyz = cross(o.normalWS,o.tangentWS) * i.tangentOS.w * unity_WorldTransformParams.w;

                //把顶点世界空间坐标存进w分量里
                float3 positionWS = TransformObjectToWorld(i.positionOS);
                o.tangentWS.w = positionWS.x;
                o.BtangentWS.w = positionWS.y;
                o.normalWS.w = positionWS.z;

                //计算纹理坐标
                o.texcoord.xy = TRANSFORM_TEX(i.texcoord,_MainTex);
                o.texcoord.zw = TRANSFORM_TEX(i.texcoord,_NormalTex);


               

                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                //顶点的世界坐标
                float3 positionWS = float3(i.tangentWS.w,i.BtangentWS.w,i.normalWS.w);

                //切线空间转换到世界空间的矩阵
                float3x3 T2W = {i.tangentWS.xyz,i.BtangentWS.xyz,i.normalWS.xyz};

                //采样切线空间下的法线纹理 并转换到世界空间
                real4 normalTex = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.texcoord.zw);
                float3 normalTS = UnpackNormalScale(normalTex,_NormalScale);
                normalTS.z=pow((1-pow(normalTS.x,2)-pow(normalTS.y,2)),0.5);//规范化法线
                float3 normalWS = mul(normalTS,T2W); //这里右乘T2W 等同于左乘T2W的逆矩阵
                

                //采样纹理
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);

                Light myLight = GetMainLight();
                real4 lightColor = real4(myLight.color,1);

                //计算漫反射
                float3 lightDirWS = normalize(myLight.direction);
                float diffuse = saturate(dot(normalWS,lightDirWS)) *0.5 + 0.5;

                 //计算高光
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - positionWS);
                float spe = saturate(dot(normalize(lightDirWS + viewDirWS),normalWS));
                spe = pow(spe,_SpecularRange);

                return (spe * _SpecularColor)  + (diffuse * lightColor * texColor  * _BaseColor);
                
            }

            ENDHLSL
        }
    }
}
