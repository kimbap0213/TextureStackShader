Shader "Unlit/StackUnlit"
{
    Properties
    { 
        [MainTexture] _BaseMap("Texture", 2DArray) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        [IntRange] _CutIndex("Cut Index", Range(0, 10)) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        //Cull Off

        Pass
        {
            Name  "URPUnlit"
            Tags {"LightMode" = "SRPDefaultUnlit"}

            HLSLPROGRAM
            #pragma target 4.5
            #pragma exclude_renderers gles d3d9
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            TEXTURE2D_ARRAY(_BaseMap);
            SAMPLER(sampler_BaseMap);
            int _CutIndex;


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            }; 
            

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                float4 positionOS = input.positionOS;
                float3 positionWS = TransformObjectToWorld(positionOS.xyz);
                // float3 positionVS = TransformWorldToView(positionWS);
                float4 positionCS = TransformWorldToHClip(positionWS);

                output.positionCS = positionCS;
                output.uv = input.uv;
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float2 baseMapUV = input.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;

                float4 texColor = float4(0, 0, 0, 0);
                float4 tmp = float4(0, 0, 0, 0);
                float alpha = 0;
                
                
                for (int i = 0; i < _CutIndex; i++)
                {
                    if(alpha < 1.0)
                    {
                        tmp = SAMPLE_TEXTURE2D_ARRAY(_BaseMap, sampler_BaseMap, baseMapUV, i);
                        alpha += tmp.a;
                        texColor.rgb += tmp.rgb * tmp.a;
                    }
                }

                alpha = clamp(alpha, 0, 1);
                texColor.a = alpha;
                
                float4 finalColor = texColor * _BaseColor;
                return finalColor;
            }
            
            ENDHLSL
        }
    }
}