Shader "URP_FX/Scanner"
{
    Properties
    {
        //[KeywordEnum(X,Y,Z)]_AXIS("Axis",float)=1
        _MainTex("MainTex",2D)= "white"{}
        [HDR]_Color("Color",color)=(0,0,0,0)
        _CenterPos("CenterPos",vector)=(0,0,0,0)
        _Radius("Radius",float)=0
        _Width("Width",float)=0
        _Bias("Bias",float)=0
        [Toggle(GRID_LINE)]_GridLine("GridLine",int)=1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"
        }
        
//        Blend SrcAlpha OneMinusSrcAlpha

        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        
        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;

        CBUFFER_END
        


        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        
        float4x4 Matrix;
        
        float4 _Color;
        float4 _CenterPos;
        float _Radius;
        float _Width;
        float _Bias;

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
            #pragma multi_compile_local GRID_LINE

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
                //??????Direction???VS???FS??????????????????????????????FS??????????????????????????????LinearEyeDepth?????????????????????????????????????????????????????????????????????
                o.Dirction = Matrix[t].xyz;
                return o;
            }

            int sobel(v2f i);

            real4 FRAG(v2f i):SV_TARGET
            {
                real depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord);
                // return depth;
                
                // 1.????????? ????????????
                // float linearEyeDepth = LinearEyeDepth(depth,_ZBufferParams);
                // float3 WSpos = _WorldSpaceCameraPos + linearEyeDepth * i.Dirction;
                // return real4(WSpos.xyz,1);

                // 2. ndc????????? 1.??????
                // float4 ndc = float4(i.texcoord.x*2 - 1, i.texcoord.y * 2 - 1, depth, 1);
                // #if UNITY_UV_STARTS_AT_TOP
                // ndc.y = -ndc.y;
                // #endif
                // float4 World= mul(UNITY_MATRIX_I_VP, ndc);
                // World.xyz = World.xyz/ World.w;
                // return real4(World.xyz,1);

                //             2.???????????????
                float3 worldPos = ComputeWorldSpacePosition(i.texcoord, depth, UNITY_MATRIX_I_VP);
                // return float4(worldPos.xyz,1);

                // 3. ndc?????? ASE???
                // #if UNITY_REVERSED_Z
                // depth = 1.0 - depth;
                // #endif
                //
                // float4 ndcPos = float4(i.texcoord.x * 2 - 1, i.texcoord.y * 2 - 1, depth * 2 - 1, 1); //NDC??????
                // float4 H = mul(unity_CameraInvProjection, ndcPos);
                // float4 V = float4((H.xyz/H.w) * float3(1,1,-1) , 1.0);
                // float4 W = mul(unity_CameraToWorld, V);
                // return float4(W.xyz,1);

                float4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                float lengthToCenter = distance(worldPos, _CenterPos.xyz);
                // return sceneColor + lengthToCenter<3;
                float scannerNearLine = smoothstep(_Radius - _Width - _Bias, _Radius - _Width, lengthToCenter);
                float scannerFarLine = smoothstep(_Radius + _Width - _Bias, _Radius + _Width, lengthToCenter);

                #if GRID_LINE
                float2 xzGrid = frac(worldPos.xz);
                float gridLine = (xzGrid.x < 0.03) | (xzGrid.y <0.03);
                return sceneColor + (scannerNearLine - scannerFarLine)*(1+gridLine)*_Color;

                #else
                return sceneColor + (scannerNearLine - scannerFarLine)*_Color;
                #endif
            }
            
            ENDHLSL

        }

    }
}