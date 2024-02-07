#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 pos : SV_POSITION;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    
    float3 tangent : TEXCOORD3;
    float3 bitangent : TEXCOORD4;
    
    
    LIGHTING_COORDS(5,6)
    //lighting coords has shadow data in it
    
};

sampler2D _MainTex;
float4 _MainTex_ST;
float _ShadowThreshold;
float3 _ShadowColor;
float3 _ShadowBandColors;

float _Gloss;
float4 _SpecularColor;

sampler2D _Normal;
float _NormalIntensity;


v2f vert(appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = UnityObjectToWorldNormal(v.normal); // pass normal to frag shader
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    
    o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
    o.bitangent = cross(o.normal, o.tangent) * (v.tangent.w * unity_WorldTransformParams.w); //correctly handle flipping/mirroring
    TRANSFER_VERTEX_TO_FRAGMENT(o); //lighting macro
    TRANSFER_SHADOW(o) //shadows
    
    return o;
}

fixed4 frag(v2f i) : SV_Target
{ 
    //normal map stuff
    float3 tangentSpaceNormal = UnpackNormal(tex2D(_Normal, i.uv)); //normal maps need to be unpacked
    tangentSpaceNormal = normalize(lerp(float3(0, 0, 1), tangentSpaceNormal, _NormalIntensity)); // 0,0,1 is a flat normal, this blends based on intensity
    
    float3x3 matrixTangentToWorld =
    {
        i.tangent.x, i.bitangent.x, i.normal.x,
        i.tangent.y, i.bitangent.y, i.normal.y,
        i.tangent.z, i.bitangent.z, i.normal.z
    };
    
    float3 norm = mul(matrixTangentToWorld, tangentSpaceNormal);
    
    
    //shadows
    float3 dirLight = normalize(UnityWorldSpaceLightDir(i.worldPos)); //gets scene directional light as a vector
    float3 lambert = saturate(dot(norm, dirLight));
    float attenuation = LIGHT_ATTENUATION(i);
    float3 outlineShadow = saturate(dot(norm, dirLight) - .5);
    
    float3 diffuseLight = saturate((lambert * attenuation) * _ShadowBandColors); //lambertian lighting formula, multiply by the light color to color the light
    float3 toonShadows = saturate(step(_ShadowThreshold, diffuseLight) + _ShadowColor);

    
    //light
    float3 view = normalize(_WorldSpaceCameraPos - i.worldPos); //gets the direction the camera is facing  
    float3 halfVector = normalize(dirLight + view); // half vector is halfway between the light and the normal
    float3 specularLight = saturate(dot(halfVector, norm)) * (lambert > 0); //blinn phong lighting formula
 
    specularLight = step((1 - (_Gloss)), specularLight) * _SpecularColor * attenuation;

    //sample the texture
    float4 col = tex2D(_MainTex, i.uv);

    return float4(toonShadows * (col * _LightColor0.xyz /* * (attenuation) */ ) + (specularLight), attenuation);
    
    //attenuation is causing problems, removing it fixed them but caused other lighting issues. Seems like an issue with TRANSFER_SHADOW itself?
}