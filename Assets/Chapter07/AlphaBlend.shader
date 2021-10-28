//透明度混合
Shader "URP/AlphaBlend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _AlphaScale("Alpha Scale",Range(0,1)) = 1
    }
    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        "IgnoreProjector" = "True"
        "RenderType"="Transparent"
        "Queue" = "Transparent" 
        }

        HLSLINCLUDE

        #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        real _AlphaScale;
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

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

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
                texColor *= _BaseColor;
                return real4(texColor.rgb,texColor.a * _AlphaScale);
            }

            ENDHLSL
        }

    }
}
