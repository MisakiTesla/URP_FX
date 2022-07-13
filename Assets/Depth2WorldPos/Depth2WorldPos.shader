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
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing//Common.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;

        CBUFFER_END
        


        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_CameraDepthTexture);

        SAMPLER(sampler_CameraDepthTexture);

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
                real depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord).r;
                // return depth;
                // 1.射线法
                float linearEyeDepth = LinearEyeDepth(depth,_ZBufferParams);
                // return LinearEyeDepth(depth,_ZBufferParams);
                // return Linear01Depth(depth,_ZBufferParams);

                float3 WSpos = _WorldSpaceCameraPos + linearEyeDepth * i.Dirction;

                // 2. ndc重建法
                // //depth d3d为0-1，opengl为-1-1 则需depth*2-1
                // #if UNITY_REVERSED_Z
                // depth = 1.0 - depth;
                // #endif
                //
                // depth = 2.0 * depth - 1.0;
                //
                // #if UNITY_UV_STARTS_AT_TOP
                // i.texcoord.y = 1-i.texcoord.y;
                // #endif
                //
                // float4 ndcPos = float4(i.texcoord.x*2 - 1, i.texcoord.y * 2 - 1, depth, 1);
                //
                // // float4 ndcPos = float4(i.texcoord.x, i.texcoord.y, depth, 1.0);
                // float4 D= mul(UNITY_MATRIX_I_VP, ndcPos );
                // // UNITY_MATRIX_I_VP 投影矩阵*相机空间矩阵 的逆矩阵
                // WSpos = D/ D.w;
                // return real4(i.texcoord.xy,0,1);


                return real4(WSpos.xyz,1);
                
            }


            ENDHLSL

        }

    }
}