Shader"Lit/Hatchmark Shader"
{
    Properties
    {
        _MainTex ("Color Map", 2D) = "white" {}
        [NoScaleOffset] _Normal ("Normal Map", 2D) = "bump" {}
        _NormalIntensity ("Normal Intensity", Range(0,1)) = 1
        [NoScaleOffset] _Hacthes ("Hatch Mark Texture", 2D) = "white" {}
        _HatchColor ("Hatch Mark Color", Color) = (0,0,0,1)
        _HatchScale("Hatch Mark Scale", int) = 1
        _ShadowThreshold ("Hatchmark Threshold", Range(-1,2)) = 0

         _HatchLayer2OffsetX("Hatch Layer 2 offset X", Range(0, 2)) = .2
         _HatchLayer2OffsetY("Hatch Layer 2 offset Y", Range(0, 2)) = .2

         _HatchLayer3OffsetX("Hatch Layer 3 offset X", Range(0, 2)) = .4
         _HatchLayer3OffsetY("Hatch Layer 3 offset Y", Range(0, 2)) = .4

         _HatchLayer4OffsetX("Hatch Layer 4 offset X", Range(0, 2)) = .8
         _HatchLayer4OffsetY("Hatch Layer 4 offset Y", Range(0, 2)) = .8
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" 
               "LightMode"="ForwardBase"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdbase 


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL; // add normals
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 bitangent : TEXCOORD4;
                SHADOW_COORDS(5) // put shadows data into TEXCOORD5
    
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _Hacthes;
            float4 _Hacthes_ST;


            float _HatchLayer2OffsetX;
            float _HatchLayer2OffsetY;

            float _HatchLayer3OffsetX;
            float _HatchLayer3OffsetY;

            float _HatchLayer4OffsetX;
            float _HatchLayer4OffsetY;

            bool _UseOneSet;
            float4 _HatchColor;

            float _HatchScale;
            sampler2D _Normal;
            float _NormalIntensity;
            float _ShadowThreshold;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    
                //all this is for normal map
                o.normal = UnityObjectToWorldNormal(v.normal); //pass normal to frag shader
                o.tangent = UnityObjectToWorldDir(v.tangent.xyz); //needed for normal map
                o.bitangent = cross(o.normal, o.tangent) * (v.tangent.w * unity_WorldTransformParams.w); //correctly handle flipping/mirroring
                    
               // compute shadows data
               TRANSFER_SHADOW(o)
    
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            { 
    
                //this is all for handling the normal map
                float3 tangentSpaceNormal = UnpackNormal(tex2D(_Normal, i.uv)); //normal maps need to be unpacked
                tangentSpaceNormal = normalize(lerp(float3(0, 0, 1), tangentSpaceNormal, _NormalIntensity)); // 0,0,1 is a flat normal, this blends based on intensity
    
                float3x3 matrixTangentToWorld =
                {
                    i.tangent.x, i.bitangent.x, i.normal.x,
                    i.tangent.y, i.bitangent.y, i.normal.y,
                    i.tangent.z, i.bitangent.z, i.normal.z
                };
    
                float3 norm = mul(matrixTangentToWorld, tangentSpaceNormal); //normals
    
                //lambert lighting
                float3 dirLight = normalize(UnityWorldSpaceLightDir(i.worldPos)); // gets scene directional light as a vector, UnityWorldSpaceLightDir is a unity command that should adapt based on type of light
                float3 lambert = saturate(dot(norm, dirLight) + _ShadowThreshold);
    

                //these masks are the threshold for each 'layer' of hatches
                //each slightly smaller than the last to make a layered effect as shadows get deeper
                float3 lambertMask1 = smoothstep(.8, 1, lambert);
                float3 lambertMask2 = smoothstep(.5, .9, lambert);
                float3 lambertMask3 = smoothstep(.1, .5, lambert);
    
                //sampling textures
                float4 hatches = tex2D(_Hacthes, i.uv * _HatchScale);
                float4 col = tex2D(_MainTex, i.uv);

                //theres gotta be a better way to do this
                //numbers at the end slightly vary the size of the hatchmarks so they look less uniform
                float4 hatches2 = tex2D(_Hacthes, (i.uv + float2(_HatchLayer2OffsetX, _HatchLayer2OffsetY)) * _HatchScale * -.8);
                float4 hatches3 = tex2D(_Hacthes, (i.uv + float2(_HatchLayer3OffsetX, _HatchLayer3OffsetY)) * _HatchScale *.6);
                float4 hatches4 = tex2D(_Hacthes, (i.uv + float2(_HatchLayer4OffsetX, _HatchLayer4OffsetY)) * _HatchScale * - .5);
    
                float3 hatchSet1 = hatches + lambertMask1;
                float3 hatchSet2 = hatches2 + lambertMask2;
                float3 hatchSet3 = hatches3 + lambertMask3;
                float3 hatchSet4 = hatches4 + lambert;
    
                //full set, all 4 hatches
                float3 hatchesFull = saturate((hatchSet1 * hatchSet2 * hatchSet3 * hatchSet4) + _HatchColor);
    
                //recieve shadows
                float shadow = SHADOW_ATTENUATION(i);
    
                //apply hatching to recieved shadows
                float3 shadowsHatched = saturate(shadow + (hatches4 * hatches3 * hatches2 * hatches) + _HatchColor);
    
             
                return float4(col.xyz * hatchesFull * shadowsHatched, 1);

}

            ENDCG


        }

        UsePass"Legacy Shaders/VertexLit/SHADOWCASTER"
    }

    Fallback"Diffuse"

}
