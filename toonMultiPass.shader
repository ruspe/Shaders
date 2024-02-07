Shader"Lit/Toon Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineSize ("Outline Size", Range(0, 0.5)) = 1
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowBandColors ("Shadow Band Colors", Color) = (1,1,1,1)

        _Gloss ("Highlight Amount", Range(0, 1)) = 1
        _SpecularColor ("Highlight Color", Color) = (1,1,1,1)

        [NoScaleOffset] _Normal ("Normals", 2D) = "bump" {}
        _NormalIntensity ("Normal Intensity", Range(0,1)) = 1

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" 
                "LightMode"="ForwardBase"}
        LOD 100

        //base pass
        Pass
        {
        Tags {"LightMode" = "ForwardBase"} //tagging pass as base pass
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "toonInclude.cginc"
            ENDCG
        }

//other lights pass
        Pass
        {
            Tags {"LightMode" = "ForwardAdd"}  
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdadd

            #define IS_IN_ADD_PASS
            #include "AutoLight.cginc"

            #include "toonInclude.cginc"

            ENDCG
        }

//outline pass
        Pass
        {
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            float _OutlineSize;
            float4 _OutlineColor;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                 o.vertex = UnityObjectToClipPos(v.vertex * (_OutlineSize + 1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
         ENDCG
        }

        UsePass"Legacy Shaders/VertexLit/SHADOWCASTER"

    }
}
