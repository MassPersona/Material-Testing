Shader "Custom/ThreeLayerBlend"
{
    Properties
    {
        _BgTex ("Background Texture", 2D) = "white" {}
        _MainTex ("Main Texture", 2D) = "white" {}
        _FgTex ("Foreground Texture", 2D) = "white" {}
        _Brightness ("Brightness", Range(0, 2)) = 1.5
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _HighlightColor ("Highlight Color", Color) = (1, 1, 1, 1)
        _ShadowIntensity ("Shadow Intensity", Range(0, 1)) = 0.25
        _HighlightIntensity ("Highlight Intensity", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            static const float3x3 ACESInputMat =
            {
                {0.59719, 0.35458, 0.04823},
                {0.07600, 0.90834, 0.01566},
                {0.02840, 0.13383, 0.83777}
            };

            // ODT_SAT => XYZ => D60_2_D65 => sRGB
            static const float3x3 ACESOutputMat =
            {
                { 1.60475, -0.53108, -0.07367},
                {-0.10208,  1.10813, -0.00605},
                {-0.00327, -0.07276,  1.07602}
            };

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

            sampler2D _BgTex;
            sampler2D _MainTex;
            sampler2D _FgTex;
            float4 _ShadowColor;
            float4 _HighlightColor;
            float _ShadowIntensity;
            float _HighlightIntensity;
            float _Brightness;

            float3 RRTAndODTFit(float3 v)
            {
                float3 a = v * (v + 0.0245786f) - 0.000090537f;
                float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
                return a / b;
            }

            float3 ACESFitted(float3 color)
            {
                color = mul(ACESInputMat, color);

                // Apply RRT and ODT
                color = RRTAndODTFit(color);

                color = mul(ACESOutputMat, color);

                // Clamp to [0, 1]
                color = saturate(color);

                return color;
            }

            // vertex shader
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            // fragment shader
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 bgCol = tex2D(_BgTex, i.uv);
                fixed4 mainTexColor = tex2D(_MainTex, i.uv);
                fixed3 mainCol = mainTexColor.rgb;
                fixed4 fgCol = tex2D(_FgTex, i.uv);

                // Apply ACES Filmic Tone Mapping to mainCol
                mainCol = ACESFitted(mainCol);
                mainCol *= _Brightness; // Apply brightness adjustment

                // Calculate luminance for split toning with rec709 coefficients
                float luminance = dot(mainCol, float3(0.299, 0.587, 0.114));
                
                float3 shadowTone = lerp(mainCol, _ShadowColor.rgb, _ShadowIntensity * -luminance);
                float3 highlightTone = lerp(mainCol, _HighlightColor.rgb, _HighlightIntensity * luminance);
                
                float3 splitTone = lerp(shadowTone, highlightTone, 0.5f);

                fixed4 tonedColor = fixed4(splitTone, mainTexColor.a);

                // Blend with background and foreground textures
                fixed4 finalCol = lerp(bgCol, tonedColor, mainTexColor.a);
                finalCol = lerp(finalCol, fgCol, fgCol.a);

                return finalCol;
            }
            ENDCG
        }
    }
}
