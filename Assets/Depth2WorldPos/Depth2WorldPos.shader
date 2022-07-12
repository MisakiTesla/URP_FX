Shader "URP_FX/Depth2WorldPos"
{
    Properties
    {
        //[KeywordEnum(X,Y,Z)]_AXIS("Axis",float)=1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }

        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;

        CBUFFER_END
        


        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        //TEXTURE2D(_CameraDepthTexture);//不需要这张图了

        //SAMPLER(sampler_CameraDepthTexture);//不需要这张图了

        TEXTURE2D(_CameraDepthNormalsTexture);
        SAMPLER(sampler_CameraDepthNormalsTexture);
        float4x4 Matrix;

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
            float3 Dirction:TEXCOORD1;
        };
        ENDHLSL

        pass
        {

            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG
            #pragma multi_compile_local _AXIS_X _AXIS_Y _AXIS_Z

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;

                int t;
                if (i.texcoord.x < 0.5 && i.texcoord.y < 0.5)
                    t = 0;
                else if (i.texcoord.x > 0.5 && i.texcoord.y < 0.5)
                    t = 1;
                else if (i.texcoord.x > 0.5 && i.texcoord.y > 0.5)
                    t = 2;
                else
                    t = 3;
                //这个Direction从VS到FS会被线性插值，所以在FS中每个片元就可以用其LinearEyeDepth乘以这个方向再加上相机的世界坐标来重建世界坐标
                o.Dirction = Matrix[t].xyz;
                return o;
            }

            int sobel(v2f i);

            real4 FRAG(v2f i):SV_TARGET
            {

                real4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                //return lerp(tex,_OutlineColor,outline);

                real4 depthnormal = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture,
                                                     i.texcoord);
                //因为这里使用了特殊的_CameraDepthNormalsTexture，所以获取01深度值的方式发生了变化
                float depth01 = depthnormal.z * 1.0 + depthnormal.w / 255.0;

                //return depth01;

                float3 WSpos = _WorldSpaceCameraPos + depth01 * i.Dirction * _ProjectionParams.z; //这样也可以得到正确的世界坐标

                return real4(frac(WSpos),1);
                
            }


            ENDHLSL

        }

    }
}