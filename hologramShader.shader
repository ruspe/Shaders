Shader"Unlit/Hologram Shader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _HoloTex ("Hologram Texture", 2D) = "gray" {}
        _HoloSpeed ("Hologram Speed", float) = .5
        _HoloColor("Hologram Color", Color) = (1,1,1,1)
        _HoloTint ("Main Texture Tint Amount", Range(0, 1)) = .2


        _FresnelStrength ("Fresnel Strength", Range(0, 5)) = 2
        _FresnelColor("FresnelColor", Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags { 
                "Queue" = "Transparent"
                "RenderType"="Transparent" 
     }
        LOD 100

        Pass
        {
            ZWrite Off //transparent

           Blend One One
         
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL; // add normals
    
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 normal : TEXCOORD3;
    
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _HoloTex;
            float4 _HoloTex_ST;
            float _HoloSpeed;
            float4 _HoloColor;
            float4 _FresnelColor;
            float _FresnelStrength;
            float _HoloTint;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal); // pass normal to frag shader
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    
    
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //get UVS in screen space
                float2 screenUVs = i.screenPosition.xy / i.screenPosition.w;
                float aspectRatio = _ScreenParams.x / _ScreenParams.y; //aspect ratio makes sure it stays the same size no matter the screen size
                screenUVs.x = screenUVs.x * aspectRatio;
                screenUVs = TRANSFORM_TEX(screenUVs, _HoloTex);
    
                //scrolling texture
                screenUVs.y -= (_Time * _HoloSpeed);
    
                // fresnel
                float3 norm = normalize(i.normal);
                float3 view = normalize(_WorldSpaceCameraPos - i.worldPos); //gets the direction the camera is facing 
 
                float fresnel = 1 - dot(view, norm); //fresnel effect
                float3 coloredFresnel = pow(fresnel, _FresnelStrength) * _FresnelColor;

                fixed4 col = tex2D(_MainTex, i.uv);
                float4 holoLines = tex2D(_HoloTex, screenUVs);
                float3 holoTexture = lerp(col.xyz, _HoloColor, _HoloTint);
                 return float4(holoTexture + (holoLines.xyz * _HoloColor) + coloredFresnel, 1);
            }

            ENDCG
        }
    }
}
