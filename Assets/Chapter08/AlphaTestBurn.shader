//基于透明度测试的烧溶
Shader "URP/AlphaTestBurn"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _Cutoff("Cutoff",Range(0,1)) = 1
        [HDR]_BurnColor("BurnColor",Color) = (2.5,1,1,1)  //灼烧光颜色
    }
    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"="TransparentCutout"
        "Queue" = "AlphaTest" 
        }

        HLSLINCLUDE

        #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Cutoff;
        real4 _BurnColor;
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
        };

        ENDHLSL

         Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                //计算纹理坐标
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);

                return o;
            }

            real4 frag(v2f i) : SV_TARGET
            {
                //采样纹理
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);
                
                //step(a,b)函数 a<=b时返回1，否则返回0
                clip(step(_Cutoff,texColor.r) - 0.01);  

                //使用lerp在原色和灼烧色中进行选择
                //Cutoff+0.1是为了实现火焰边缘灼烧效果
                //假设cutOff为0.5 那么r<0.5的地方都会被clip掉 r位于0.5到0.6的地方会显示灼烧色 r>0.6的地方会显示原色
                texColor = lerp(texColor,_BurnColor,step(texColor.r,saturate(_Cutoff + 0.1)));

                return texColor * _BaseColor;
            }

            ENDHLSL
        }




    }
}
