Shader "Unlit/D2WClassic"
{
    Properties
    {

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        ZTest Always
        Cull off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _CameraDepthTexture;
                    float4x4 Matrix;
        float4x4 invVPMatrix;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

                // return Linear01Depth(depth);
                // return depth;
                // return float4(depth,0,0,1);
                // return float4(i.uv,0,1);
                #if UNITY_REVERSED_Z
                depth = 1-depth;
                #endif
                
                float4 ndcPos = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 - 1, 1); //NDC坐标

                float4 viewHPos = mul(unity_CameraInvProjection, ndcPos);//齐次坐标
                float3 viewPos = viewHPos.xyz/viewHPos.w;
                viewPos = viewPos * float3(1,1,-1);//左手系 => 右手系
                
                float4 W = mul(unity_CameraToWorld, float4(viewPos,1.0));

                return float4(W.xyz,1.0);

            }
            ENDCG
        }
    }
}
