Includes = {
	"cw/pdxmesh_blendshapes.fxh"
	"cw/pdxmesh.fxh"
	"cw/utility.fxh"
	"cw/shadow.fxh"
	"cw/camera.fxh"
	"cw/alpha_to_coverage.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_fog.fxh"
	"jomini/portrait_accessory_variation.fxh"
	"jomini/portrait_decals.fxh"
	"jomini/portrait_user_data.fxh"
	"constants.fxh"
	"standardfuncsgfx.fxh"
	"jomini/ek2_functions.fxh"
}

PixelShader =
{
	TextureSampler DiffuseMap
	{
		Index = 0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler PropertiesMap
	{
		Index = 1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler NormalMap
	{
		Index = 2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler SSAOColorMap
	{
		Index = 3
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler EnvironmentMap
	{
		Ref = JominiEnvironmentMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		Type = "Cube"
	}
	TextureSampler DiffuseMapOverride
	{
		Index = 9
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler NormalMapOverride
	{
		Index = 10
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler PropertiesMapOverride
	{
		Index = 11
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler ShadowTexture
	{
		Ref = PdxShadowmap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		CompareFunction = less_equal
		SamplerType = "Compare"
		MaxAnisotropy = 0
	}

	VertexStruct PS_COLOR_SSAO
	{
		float4 Color : PDX_COLOR0;
		float4 SSAOColor : PDX_COLOR1;
	};

	VertexStruct PS_OUTPUT_SELECTION
	{
		uint Identifier : PDX_COLOR;
	};
}

VertexStruct VS_OUTPUT_PDXMESHPORTRAIT
{
    float4 	Position		: PDX_POSITION;
	float3 	Normal			: TEXCOORD0;
	float3 	Tangent			: TEXCOORD1;
	float3 	Bitangent		: TEXCOORD2;
	float2 	UV0				: TEXCOORD3;
	float2 	UV1				: TEXCOORD4;
	float2 	UV2				: TEXCOORD5;
	float3 	WorldSpacePos	: TEXCOORD6;
	# This instance index is used to fetch custom user data from the Data[] array (see pdxmesh.fxh)
	uint 	InstanceIndex	: TEXCOORD7;
};

# SCourtSceneLightConstants::MaxLightCount in cpp code controls light array sizes
ConstantBuffer( SceneLightConstants )
{
	float4 Light_Color_Intensity[20];
	float4 Light_Position_Radius[20];
	float4 Light_Direction_Type[20];
	float4 Light_InnerCone_OuterCone_ShadowToUse[20];
	int CurrentLightCount;
	float EmissiveStrength;
	float GemCubeStrength;
	float SecondaryShadowStrength;
	float ShadowDepthFactor;
	float _1; // Alignment
	float _2;
	float _3;
};

ConstantBuffer( 5 )
{
	float4 vPaletteColorSkin;
	float4 vPaletteColorEyes;
	float4 vPaletteColorHair;
	float4 vSkinPropertyMult;
	float4 vEyesPropertyMult;
	float4 vHairPropertyMult;

	float4  PatternColorOverrides[16];

	int DecalCount;
	int PreSkinColorDecalCount
	int TotalDecalCount;
	int _4; // Alignment

	float HasDiffuseMapOverride;
	float HasNormalMapOverride;
	float HasPropertiesMapOverride;
	float HoverMult;
};

# CCourtSceneShadowMap::MaxShadows in cpp code controls shadow array sizes
# Must match in size with CCourtSceneShadowMap::MaxShadows
ConstantBuffer( SceneShadowConstants )
{	
	float4x4 _ShadowMapTextureMatrices[4];
	float4 _ProjectionFactors_ShadowType[4]; // Contains the "r2c2" and "r2c3" factors from the projection matrix
	float4 _AtlasOffsetAndScale[4*6]; // Contains offset and scale ("size") of the atlas entry, for cubemaps there are 6 entries in EGfxCubeMapFace order starting from lights "AtlasInfoIndex"
	float4 _ShadowFade;
	uint _NumShadows;
	int _SceneShadowConstants2;
	int _SceneShadowConstants3;
	int _SceneShadowConstants4;
}

Code
[[
	// Must match in size with CCourtSceneShadowMap::MaxShadows
	#define SHADOWS_COUNT 4
	#define LIGHT_TYPE_NONE 0
	#define LIGHT_TYPE_DIRECTIONAL 1
	#define LIGHT_TYPE_SPOTLIGHT 2
	#define LIGHT_TYPE_POINTLIGHT 3
	#define LIGHT_TYPE_DISC 4
	#define LIGHT_TYPE_SPHERE 5
]]

VertexShader = {

	Code
	[[
		VS_OUTPUT_PDXMESHPORTRAIT ConvertOutput( VS_OUTPUT_PDXMESH In )
		{
			VS_OUTPUT_PDXMESHPORTRAIT Out;
			
			Out.Position = In.Position;
			Out.Normal = In.Normal;
			Out.Tangent = In.Tangent;
			Out.Bitangent = In.Bitangent;
			Out.UV0 = In.UV0;
			Out.UV1 = In.UV1;
			Out.UV2 = In.UV2;
			Out.WorldSpacePos = In.WorldSpacePos;
			return Out;
		}
	]]

	MainCode VS_standard
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT_PDXMESHPORTRAIT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDXMESHPORTRAIT Out = ConvertOutput( PdxMeshVertexShaderStandard( Input ) );
				Out.InstanceIndex = Input.InstanceIndices.y;
				return Out;
			}
		]]
	}
}

PixelShader =
{
	Code
	[[
		void CalculateLightingFromAreaLight( SMaterialProperties MaterialProps, SLightingProperties LightingProps, out float3 DiffuseOut, out float3 SpecularOut, float3 SpecToLightDir )
		{
			float3 H = normalize( LightingProps._ToCameraDir + LightingProps._ToLightDir );
			float NdotV = saturate( dot( MaterialProps._Normal, LightingProps._ToCameraDir ) ) + 1e-5;
			float NdotL = saturate( dot( MaterialProps._Normal, LightingProps._ToLightDir ) ) + 1e-5;
			float NdotH = saturate( dot( MaterialProps._Normal, H ) );
			float LdotH = saturate( dot( LightingProps._ToLightDir, H ) );
			
			float3 LightIntensity = LightingProps._LightIntensity * NdotL * LightingProps._ShadowTerm;
			
			// Diffuse
			float DiffuseBRDF = CalcDiffuseBRDF( NdotV, NdotL, LdotH, MaterialProps._PerceptualRoughness );
			DiffuseOut = DiffuseBRDF * MaterialProps._DiffuseColor * LightIntensity;

			// Specular
			H = normalize( LightingProps._ToCameraDir + SpecToLightDir );
			NdotL = saturate( dot( MaterialProps._Normal, SpecToLightDir ) ) + 1e-5;
			NdotH = saturate( dot( MaterialProps._Normal, H ) );
			LdotH = saturate( dot( SpecToLightDir, H ) );

			float3 SpecularBRDF = CalcSpecularBRDF( MaterialProps._SpecularColor, LdotH, NdotH, NdotL, NdotV, MaterialProps._Roughness );
			SpecularOut = SpecularBRDF * LightIntensity;	
		}

		float SampleShadowMapAtlas( float2 UV, float Depth, float2 Offset, float2 Scale )
		{
			//return PdxTex2DCmpLod0( ShadowTexture, UV * Scale + Offset, Depth - Bias );
			
			float RandomAngle = CalcRandom( round( ShadowScreenSpaceScale * UV ) ) * 3.14159 * 2.0;
			float2 Rotate = float2( cos( RandomAngle ), sin( RandomAngle ) );
			
			// Sample each of them checking whether the pixel under test is shadowed or not
			float ShadowTerm = 0.0;
			for( int i = 0; i < NumSamples; i++ )
			{
				float4 Samples = DiscSamples[i] * KernelScale;
				
				float2 OffsetUV = saturate( UV + RotateDisc( Samples.xy, Rotate ) );
				float2 SampleUV = OffsetUV * Scale + Offset;
				ShadowTerm += PdxTex2DCmpLod0( ShadowTexture, SampleUV, Depth - Bias );
				
				OffsetUV = saturate( UV + RotateDisc( Samples.zw, Rotate ) );
				SampleUV = OffsetUV * Scale + Offset;
				ShadowTerm += PdxTex2DCmpLod0( ShadowTexture, SampleUV, Depth - Bias );
			}
			
			// Get the average
			ShadowTerm *= 0.5; // We have 2 samples per "sample"
			ShadowTerm = ShadowTerm / float( NumSamples );
			
			return lerp( 1.0, ShadowTerm, ShadowFadeFactor );
		}
		
		float CalcDepthFadeFactor( float Depth, int Index )
		{
			float DepthFactor = _ShadowFade[ Index ] < 0.f ? ShadowDepthFactor : _ShadowFade[ Index ];
			return ( 1.0 - Depth ) * DepthFactor;
		}
		
		float CalcShadow( float3 WorldSpacePos, int ShadowIndex )
		{
			float4 ShadowProj = mul( _ShadowMapTextureMatrices[ShadowIndex], float4( WorldSpacePos, 1.0 ) );
			ShadowProj.xyz = ShadowProj.xyz / ShadowProj.w;
			
			float4 OffsetAndScale = _AtlasOffsetAndScale[ShadowIndex * 6];			
			float ShadowTerm = SampleShadowMapAtlas( ShadowProj.xy, ShadowProj.z, OffsetAndScale.xy, OffsetAndScale.zw );
			
			float3 FadeFactor = saturate( float3( ( 1.0 - abs( 0.5 - ShadowProj.xy ) * 2.0 ) * 32.0, CalcDepthFadeFactor( ShadowProj.z, ShadowIndex ) ) ); // 32 is just a random strength on the fade
			ShadowTerm = lerp( 1.0, ShadowTerm, min( min( FadeFactor.x, FadeFactor.y ), FadeFactor.z ) );
			
			return ShadowTerm;
		}
		
		// This will calculate the UV and FaceIndex for a Cube face from LightSpacePosition (https://www.gamedev.net/forums/topic/687535-implementing-a-cube-map-lookup-function/5337472/)
		float2 SampleCube( float3 LightSpacePosition, out int FaceIndex )
		{
			float3 AbsPosition = abs( LightSpacePosition );
			float2 UV;
			if ( AbsPosition.z >= AbsPosition.x && AbsPosition.z >= AbsPosition.y )
			{
				FaceIndex = LightSpacePosition.z < 0.0 ? 5 : 4;
				UV = float2( LightSpacePosition.z < 0.0 ? -LightSpacePosition.x : LightSpacePosition.x, -LightSpacePosition.y ) * ( 0.5 / AbsPosition.z );
			}
			else if ( AbsPosition.y >= AbsPosition.x )
			{
				FaceIndex = LightSpacePosition.y < 0.0 ? 3 : 2;
				UV = float2( LightSpacePosition.x, LightSpacePosition.y < 0.0 ? -LightSpacePosition.z : LightSpacePosition.z ) * ( 0.5 / AbsPosition.y );
			}
			else
			{
				FaceIndex = LightSpacePosition.x < 0.0 ? 1 : 0;
				UV = float2( LightSpacePosition.x < 0.0 ? LightSpacePosition.z : -LightSpacePosition.z, -LightSpacePosition.y ) * ( 0.5 / AbsPosition.x );
			}
			return UV + 0.5;
		}
		
		// Calculate shadow map space projected depth (https://community.khronos.org/t/glsl-cube-shadows-projecting/64080/14)
		float CalcCubeShadowDepth( float3 LightSpacePosition, float2 ProjectionFactors )
		{
			float3 AbsPosition = abs( LightSpacePosition );
			float MaxZ = max( AbsPosition.x, max( AbsPosition.y, AbsPosition.z ) );

			// This is equivalent with - float4 ClipPos = "ProjectionMatrix" * float4( AbsPosition, 1.0 ); return ClipPos.z / ClipPos.w;
			return ( ProjectionFactors.x + ProjectionFactors.y / MaxZ );
		}

		float CalcCubeShadow( float3 LightSpacePosition, int ShadowIndex )
		{
			int FaceIndex = 0;
			float2 UV = SampleCube( LightSpacePosition, FaceIndex );
			float Depth = CalcCubeShadowDepth( LightSpacePosition, _ProjectionFactors_ShadowType[ShadowIndex].xy );
			
			float4 OffsetAndScale = _AtlasOffsetAndScale[ShadowIndex * 6 + FaceIndex];
			float ShadowTerm = SampleShadowMapAtlas( UV, Depth, OffsetAndScale.xy, OffsetAndScale.zw );
			
			float FadeFactor = saturate( CalcDepthFadeFactor( Depth, ShadowIndex ) );
			ShadowTerm = lerp( 1.0, ShadowTerm, FadeFactor );
			
			return ShadowTerm;
		}
		
		bool IsCubeShadow( int ShadowIndex )
		{
			return ( _ProjectionFactors_ShadowType[ShadowIndex].z == 1.0 );
		}
		
		void CalculateShadowTerms( float3 WorldSpacePos, inout float ShadowTerm[ SHADOWS_COUNT ] )
		{
			// Note, light list is sorted so that shadow generators are first, this is why we can just loop over _NumShadows here
			for( int ShadowIndex = 0; ShadowIndex < _NumShadows; ++ShadowIndex )
			{
				if ( IsCubeShadow( ShadowIndex ) )
				{
					float3 LightSpacePosition = WorldSpacePos - Light_Position_Radius[ShadowIndex].xyz;
					ShadowTerm[ ShadowIndex ] = CalcCubeShadow( LightSpacePosition, ShadowIndex );
				}
				else
				{
					ShadowTerm[ ShadowIndex ] = CalcShadow( WorldSpacePos, ShadowIndex );
				}
			}
		}

		float3 RayPlaneIntersect( float3 RayOrigin , float3 RayDirection , float3 PlaneOrigin , float3 PlaneNormal )
		{
			float Distance = dot( PlaneNormal , PlaneOrigin - RayOrigin ) / dot( PlaneNormal , RayDirection );
			return RayOrigin + RayDirection * Distance;
		}

		// Standard inverse square falloff
		float CalculatePointLightAttenuation( float3 PosToLight, float Radius )
		{
			float DistanceToLight = length( PosToLight );
			float Attenuation = 1.0f / max( DistanceToLight * DistanceToLight, 0.001f );

			// Technically physically incorrect, scales radius smoothly
			// A very high radius scale will move the light towars a physically correct attenuation
			float step = ToLinear( smoothstep( -Radius, 0.0f, -DistanceToLight ) );

			return Attenuation * step;
		}

		float GetAngleAttenuation( float3 NormalizedLightVector, float3 LightDir, float InnerAngle, float OuterAngle )
		{
			float CosInner = cos( InnerAngle );
			float CosOuter = cos( OuterAngle );

			float LightAngleScale = 1.0f / max( 0.001f, ( CosInner - CosOuter ) );
			float LightAngleOffset = -CosOuter * LightAngleScale;
		
			float cd = dot( LightDir, NormalizedLightVector );
			float attenuation = saturate ( cd * LightAngleScale + LightAngleOffset );
			// smooth the transition
			attenuation *= attenuation;
			
			return attenuation;
		}

		float illuminanceSphereOrDisk( float cosTheta, float sinSigmaSqr )
		{
		 	float sinTheta = sqrt( 1.0f - cosTheta * cosTheta );

		 	float illuminance = 0.0f;

			if( cosTheta * cosTheta > sinSigmaSqr )
			{
				illuminance = PI * sinSigmaSqr * saturate( cosTheta );
			}
			else
			{
				float x = sqrt (1.0f / sinSigmaSqr - 1.0f );
				float y = -x * ( cosTheta / sinTheta );
				float sinThetaSqrtY = sinTheta * sqrt ( 1.0f - y * y );
				illuminance = ( cosTheta * acos( y ) - x * sinThetaSqrtY ) * sinSigmaSqr + 
				atan( sinThetaSqrtY / x );
			}
			return max( illuminance, 0.0f );
		}

		float CalcSphereDiffuse( float3 ToLight, float LightRadius, float3 Normal )
		{
			float3 ToLightNormalized = normalize( ToLight );
			float SquareDist = dot( ToLight, ToLight );

			// Sphere evaluation
			float cosTheta = clamp ( dot( Normal, ToLightNormalized ), -0.999f, 0.999f );

			float SqrLightRadius = LightRadius * LightRadius ;
			float sinSigmaSqr = min( SqrLightRadius / SquareDist, 0.9999f );
			float illuminance = illuminanceSphereOrDisk( cosTheta, sinSigmaSqr );

			return illuminance;
		}

		float CalcDiscDiffuse( float3 ToLight, float LightRadius, float3 Normal, float3 LightDir )
		{
			float3 ToLightNormalized = normalize( ToLight );
			float SquareDist = dot( ToLight, ToLight );

			// Disk evaluation
			float cosTheta = dot ( Normal, ToLightNormalized );
			float SqrLightRadius = LightRadius * LightRadius;
			// Do not let the surface penetrate the light
			float sinSigmaSqr = SqrLightRadius / ( SqrLightRadius + max ( SqrLightRadius, SquareDist ) );
			// Multiply by saturate ( dot ( LightDir , -L)) to better match ground truth .
			float illuminance = illuminanceSphereOrDisk( cosTheta, sinSigmaSqr )
			* saturate ( dot( LightDir, -ToLightNormalized ) );

			return illuminance;
		}

		float3 CalcSphereSpecMRP( float3 LightPosition, float LightRadius, float3 WorldSpacePos, float3 ViewVectorR )
		{
			float3 ToLight = LightPosition - WorldSpacePos;

			float3 CenterToRay = dot( ToLight, ViewVectorR ) * ViewVectorR - ToLight;
			float3 ClosestPoint = ToLight + CenterToRay * saturate( LightRadius / length( CenterToRay ) );

			return ClosestPoint;
		}

		float3 CalcDiscSpecMRP( float3 LightPosition, float LightRadius, float3 WorldSpacePos, float3 ViewVectorR, float3 LightDir )
		{
			float3 ToLight = LightPosition - WorldSpacePos;

			float SpecularAttenuation = saturate( abs( dot( LightDir, ViewVectorR ) ) );

			float3 ClosestPoint = ToLight;
			if( SpecularAttenuation > 0.0f )
			{
				float3 PlaneIntersect = RayPlaneIntersect( WorldSpacePos, ViewVectorR, LightPosition, LightDir );

				float3 CenterToRay = PlaneIntersect - LightPosition;
				ClosestPoint = ToLight + CenterToRay * saturate( LightRadius / length( CenterToRay ) );
			}

			return ClosestPoint;
		}	
		
		void CalculateSceneLights( float3 WorldSpacePos, float ShadowTerm[ SHADOWS_COUNT ], SMaterialProperties MaterialProps, inout float3 DiffuseLightOut, inout float3 SpecularLightOut )
		{
			for( int i = 0; i < CurrentLightCount; ++i )
			{
				float3 DiffuseLight = vec3( 0.0f );
				float3 SpecularLight = vec3( 0.0f );

				//Scale color by ShadowTerm
				int ShadowToUse = int( Light_InnerCone_OuterCone_ShadowToUse[ i ].z );
				float LightShadowTerm = 1.0;
				if ( ShadowToUse >= 0 )
				{
					LightShadowTerm = ShadowTerm[ ShadowToUse ];
				}
				else
				{
					float ShadowDecreace = 0.f;
					for ( int s = 0; s < SHADOWS_COUNT; ++s )
					{
						ShadowDecreace += lerp( ShadowTerm[ s ], 1.f, SecondaryShadowStrength );
					}
					ShadowDecreace /= SHADOWS_COUNT;
					LightShadowTerm = clamp( ShadowDecreace, 0.f, 1.f );
				}

				float4 ColorIntensity = Light_Color_Intensity[i];
				
				float3 PosToLight = Light_Position_Radius[i].xyz - WorldSpacePos;
				float DistanceToLight = length( PosToLight );
				float3 ViewVector = normalize( CameraPosition - WorldSpacePos );
				//Light types
				if( Light_Direction_Type[i].w == LIGHT_TYPE_SPOTLIGHT )
				{
					float3 LightDirection = normalize( Light_Direction_Type[i].xyz );
					
					float ScaledRadius = Light_Position_Radius[i].w;
					float Attenuation = CalculatePointLightAttenuation( PosToLight, ScaledRadius );
					float3 LightColorIntensity = Light_Color_Intensity[i].xyz * Light_Color_Intensity[i].w * 1000.0f * Attenuation;

					// Angle Attenuation
					float InnerAngle = RemapClamped( Light_InnerCone_OuterCone_ShadowToUse[i].x, 0.0f, 1.0f, 0.0f, PI / 2.0f );
					float OuterAngle = RemapClamped( Light_InnerCone_OuterCone_ShadowToUse[i].y, 0.0f, 1.0f, 0.0f, PI / 2.0f );
					LightColorIntensity *= GetAngleAttenuation( normalize( PosToLight ), -LightDirection, InnerAngle, OuterAngle );

					// TODO: Could be cleaned up better
					SLightingProperties LightingProps;
					LightingProps._ToCameraDir = ViewVector;
					LightingProps._ToLightDir = normalize( PosToLight );
					LightingProps._LightIntensity = LightColorIntensity;
					LightingProps._ShadowTerm = LightShadowTerm;
					LightingProps._CubemapIntensity = 0.0;
					LightingProps._CubemapYRotation = Float4x4Identity();
					CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				}
				else if( Light_Direction_Type[i].w == LIGHT_TYPE_POINTLIGHT )
				{
					float ScaledRadius = Light_Position_Radius[i].w;
					float Attenuation = CalculatePointLightAttenuation( PosToLight, ScaledRadius );
					float3 LightColorIntensity = Light_Color_Intensity[i].xyz * Light_Color_Intensity[i].w * 1000.0f * Attenuation;

					// TODO: Could be cleaned up better
					SLightingProperties LightingProps;
					LightingProps._ToCameraDir = ViewVector;
					LightingProps._ToLightDir = normalize( PosToLight );
					LightingProps._LightIntensity = LightColorIntensity;
					LightingProps._ShadowTerm = LightShadowTerm;
					LightingProps._CubemapIntensity = 0.0;
					LightingProps._CubemapYRotation = Float4x4Identity();
					CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				}
				else if( Light_Direction_Type[i].w == LIGHT_TYPE_DIRECTIONAL )
				{
					SLightingProperties LightingProps;
					LightingProps._ToCameraDir = ViewVector;
					LightingProps._ToLightDir = -Light_Direction_Type[i].xyz;
					LightingProps._LightIntensity = ColorIntensity.rgb;
					LightingProps._ShadowTerm = LightShadowTerm;
					LightingProps._CubemapIntensity = 0.0f;
					LightingProps._CubemapYRotation = Float4x4Identity();
					CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				}
				else if( Light_Direction_Type[i].w == LIGHT_TYPE_DISC )
				{
					// Frostbite Disc					
					float3 LightDirection = normalize( Light_Direction_Type[i].xyz );
					float LightIntensity = CalcDiscDiffuse( PosToLight, Light_Position_Radius[i].w, MaterialProps._Normal, LightDirection );
					float3 LightColorIntensity = Light_Color_Intensity[i].xyz * Light_Color_Intensity[i].w * LightIntensity;
					
					// Angle Attenuation
					float InnerAngle = RemapClamped( Light_InnerCone_OuterCone_ShadowToUse[i].x, 0.0f, 1.0f, 0.0f, PI );
					float OuterAngle = RemapClamped( Light_InnerCone_OuterCone_ShadowToUse[i].y, 0.0f, 1.0f, 0.0f, PI );
					float HalfOuterAngle = OuterAngle * 0.5f;
					float3 VirtualPos = Light_Position_Radius[i].xyz - LightDirection * ( Light_Position_Radius[i].w / tan( HalfOuterAngle ) );
					LightColorIntensity *= GetAngleAttenuation( normalize( VirtualPos - WorldSpacePos ), -LightDirection, InnerAngle, OuterAngle );
					
					float3 ViewVectorR = reflect( ViewVector, MaterialProps._Normal );
					float3 ClosestPoint = CalcDiscSpecMRP( Light_Position_Radius[i].xyz, Light_Position_Radius[i].w, WorldSpacePos, ViewVectorR, LightDirection );
					ClosestPoint = normalize( ClosestPoint );

					// TODO: Could be cleaned up better
					SLightingProperties LightingProps;
					LightingProps._ToCameraDir = ViewVector;
					LightingProps._ToLightDir = normalize( PosToLight );
					LightingProps._LightIntensity = LightColorIntensity;
					LightingProps._ShadowTerm = LightShadowTerm;
					LightingProps._CubemapIntensity = 0.0;
					LightingProps._CubemapYRotation = Float4x4Identity();
					CalculateLightingFromAreaLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight, ClosestPoint );
				}
				else if( Light_Direction_Type[i].w == LIGHT_TYPE_SPHERE )
				{
					// Frostbite Sphere
					float LightIntensity = CalcSphereDiffuse( PosToLight, Light_Position_Radius[i].w, MaterialProps._Normal ) * 0.1f;
					float3 LightColorIntensity = Light_Color_Intensity[i].xyz * Light_Color_Intensity[i].w * LightIntensity;
					float3 ViewVectorR = reflect( ViewVector, MaterialProps._Normal );
					float3 ClosestPoint = CalcSphereSpecMRP( Light_Position_Radius[i].xyz, Light_Position_Radius[i].w, WorldSpacePos, ViewVectorR );
					ClosestPoint = normalize( ClosestPoint );

					// TODO: Could be cleaned up better
					SLightingProperties LightingProps;
					LightingProps._ToCameraDir = ViewVector;
					LightingProps._ToLightDir = normalize( PosToLight );
					LightingProps._LightIntensity = LightColorIntensity;
					LightingProps._ShadowTerm = LightShadowTerm;
					LightingProps._CubemapIntensity = 0.0;
					LightingProps._CubemapYRotation = Float4x4Identity();
					CalculateLightingFromAreaLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight, ClosestPoint );
				}
			
				// Return
				DiffuseLightOut += DiffuseLight;
				SpecularLightOut += SpecularLight;
			}
		}

		void DebugReturn( inout float3 Out, SMaterialProperties MaterialProps, SLightingProperties LightingProps, PdxTextureSamplerCube EnvironmentMap, float3 SssColor, float SssMask )
		{
			#if defined(PDX_DEBUG_PORTRAIT_SSS_MASK)
			Out = SssMask;
			#elif defined(PDX_DEBUG_PORTRAIT_SSS_COLOR)
			Out = SssColor;
			#else
			DebugReturn( Out, MaterialProps, LightingProps, EnvironmentMap );
			#endif
		}

		void AddHoverHighlight( inout float3 Color, float3 TbnToNormal, float3 ToCameraDir, float HoverMult )
		{
			if ( HoverMult <= 0.f )
			{
				return;
			}
			float FresnelFactor = Fresnel( abs( dot( ToCameraDir, normalize( TbnToNormal ) ) ), HOVER_FRESNEL_BIAS, HOVER_FRESNEL_POWER );
			Color += HOVER_COLOR * HOVER_INTENSITY * FresnelFactor * HoverMult;
		}

		float3 CommonPixelShader( float4 Diffuse, float4 Properties, float3 NormalSample, in VS_OUTPUT_PDXMESHPORTRAIT Input, float HoverMult )
		{
			float3x3 TBN = Create3x3( normalize( Input.Tangent ), normalize( Input.Bitangent ), normalize( Input.Normal ) );
			float3 Normal = normalize( mul( NormalSample, TBN ) );
			
			SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, saturate( Properties.a ), Properties.g, Properties.b );
			SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowTexture );

			#ifdef GEMCUBE
				LightingProps._CubemapIntensity = GemCubeStrength;
			#endif

			//EK2
			float3 DiffuseIBL = vec3(0.0);
			float3 SpecularIBL = vec3(0.0);
			float3 DiffuseLight = vec3(0.0);
			float3 SpecularLight = vec3(0.0);

			// Must match in size with CCourtSceneShadowMap::MaxShadows
			float Shadows[ SHADOWS_COUNT ] = 
			#ifdef PDX_GLSL
				float[ SHADOWS_COUNT ]( 1.0, 1.0, 1.0, 1.0 );
			#else
				{ 1.0, 1.0, 1.0, 1.0 };
			#endif

			#if defined PARALLAX || defined REFRACT

				static const float FresnelPower 		= 	1.5f;
				static const float FresnelBrightness 	= 	1.0f;
				static const float InnerThickness 		= 	350.0f; //Base thickness/depth of inner texture

				float4 GlassMasks = PdxTex2D( GlassMask, Input.UV0 );

				float3 ToCameraDir = normalize(CameraPosition - Input.WorldSpacePos);
				float3 ReflectVector = reflect(ToCameraDir,Normal);
				ReflectVector.y = -ReflectVector.y;
				float FresnelTerm = pow(1.0f - dot(ToCameraDir,Normal),FresnelPower)*FresnelBrightness;

				float4 CubeMap = PdxTexCube(EnvironmentMap,ReflectVector);

				//Convert CameraDir to Tangent Space with inverted TBN
				float3x3 iTBN = transpose( TBN );
				float3 ToCameraDirTS = normalize( mul( ToCameraDir, iTBN ) );

				//EK2 REFRACT
				#ifdef REFRACT


					static const float MaterialIOR		 	= 	1.52f;

					//Refraction
					float3 RefractVector = refract(ToCameraDir,-Normal,1.0f/MaterialIOR);
					RefractVector.y = -RefractVector.y;
					RefractVector.z = -RefractVector.z;
					float4 RefractColor = PdxTexCube(EnvironmentMap,RefractVector);

					//Tint
					RefractColor.rgb *= Diffuse.rgb;

					//Reflect
					float4 Albedo1 = lerp(RefractColor,CubeMap,FresnelTerm*Properties.a);

					SMaterialProperties MaterialPropsRefract = MaterialProps;
					SLightingProperties LightingPropsRefract = LightingProps;

					//Smoother lighting
					LightingPropsRefract._ShadowTerm = lerp(1.0f,LightingProps._ShadowTerm,1.0f-GlassMasks.r);

					//Remove metalness
					MaterialPropsRefract._Metalness = lerp(0.0f,MaterialProps._Metalness,1.0f-GlassMasks.r);

					//Assign new DiffuseColor/SpecularColor
					MaterialPropsRefract._DiffuseColor = lerp(float3(1.0f,1.0f,1.0f),MaterialProps._DiffuseColor,1.0f-GlassMasks.r);
					MaterialPropsRefract._SpecularColor = lerp(float3(1.0f,1.0f,1.0f),MaterialProps._SpecularColor,1.0f-GlassMasks.r);

					CalculateLightingFromIBL( MaterialPropsRefract, LightingPropsRefract, EnvironmentMap, DiffuseIBL, SpecularIBL );

					CalculateShadowTerms( Input.WorldSpacePos, Shadows );
					CalculateSceneLights( Input.WorldSpacePos, Shadows, MaterialPropsRefract, DiffuseLight, SpecularLight );

					float3 Lighting = DiffuseIBL + SpecularIBL + DiffuseLight + SpecularLight;
					Albedo1.rgb = lerp (Albedo1.rgb, Albedo1.rgb * 3.0f, Lighting);

					#ifndef PARALLAX
						float3 Color = lerp (Albedo1.rgb, Lighting.rgb, 1.0f-GlassMasks.r);
					#else
						float3 Color1 = lerp (Albedo1.rgb, Lighting.rgb, 1.0f-GlassMasks.r);
						DiffuseIBL = vec3(0.0);
						SpecularIBL = vec3(0.0);
						DiffuseLight = vec3(0.0);
						SpecularLight = vec3(0.0);
					#endif

				#endif
				
				//EK2 Parallax shader - Based on NIFSCOPE skyrim multi-layer-parallax shader.
				#ifdef PARALLAX

					static const float OuterRefraction 		= 	0.2f;   //Dictates how smooth the inner texture is. 0.0f not distorted by surface normals, and 1.0f fully distorted by surface normals.
					static const float NormalSmoothing 		= 	0.0f;   //Reduces the effect of lighting by smoothing normals, 0.0f lights the model as normal, 1.0f gives almost fullbright effect.
					float2 InnerScale 						= 	2.0f;  //Inner texture tiling factor

					// Texel size
					float2 DiffuseSize;
					float2 InnerSize;
					PdxTex2DSize(DiffuseMap, DiffuseSize);
					PdxTex2DSize(InnerMap, InnerSize);
					InnerScale *= DiffuseSize/InnerSize;

					// Mix between the face normal and the normal map based on the refraction scale
					float3 MixedNormal = lerp( float3(0.0f,0.0f,1.0f), NormalSample, clamp( OuterRefraction, 0.0, 1.0 ) );
					float3 Parallax = ParallaxOffset( Input.UV0, InnerScale, ToCameraDirTS, MixedNormal, InnerThickness * GlassMasks.g , Input.UV0 , DiffuseSize);
					
					// Sample the inner map at the offset coords
					float3 Inner = PdxTex2D( InnerMap, Parallax.xy * InnerScale ).rgb;
					//Inner = Inner+Diffuse.rgb*0.5f;

					//Inner = lerp (Inner,CubeMap.rgb,FresnelTerm*Properties.a);
					// Mix inner/outer layer based on fresnel
					float OuterMix = max(FresnelTerm*FresnelTerm*2.0f, 1.0f-GlassMasks.b);
					float3 Albedo2 = lerp( Inner, Diffuse.rgb, OuterMix );
					
					//Environment reflections
					Albedo2 += CubeMap.rgb*Properties.a;

					SMaterialProperties MaterialPropsParallax = MaterialProps;
					SLightingProperties LightingPropsParallax = LightingProps;

					//Remove metalness
					MaterialPropsParallax._Metalness = lerp(0.0f, MaterialProps._Metalness, 1.0f-GlassMasks.b);

					//Assign new DiffuseColor/SpecularColor
					MaterialPropsParallax._DiffuseColor = lerp(Albedo2, MaterialProps._DiffuseColor, 1.0f-GlassMasks.b);
					MaterialPropsParallax._SpecularColor = lerp(Diffuse.rgb, MaterialProps._SpecularColor, 1.0f-GlassMasks.b);

					//Reduce the "depth" of normals to soften the lighting and give translucent effect
					MaterialPropsParallax._Normal = lerp(MaterialProps._Normal, float3(0.0f,0.0f,1.0f), min(NormalSmoothing,GlassMasks.b));

					//Smoother lighting
					LightingPropsParallax._ShadowTerm = lerp(1.0f,LightingProps._ShadowTerm,1.0f-GlassMasks.b);


					CalculateLightingFromIBL( MaterialPropsParallax, LightingPropsParallax, EnvironmentMap, DiffuseIBL, SpecularIBL );

					CalculateShadowTerms( Input.WorldSpacePos, Shadows );
					CalculateSceneLights( Input.WorldSpacePos, Shadows, MaterialPropsParallax, DiffuseLight, SpecularLight );

					#ifndef REFRACT
						float3 Color = DiffuseIBL + SpecularIBL + DiffuseLight + SpecularLight;
					#else

						float3 Color2 = DiffuseIBL + SpecularIBL + DiffuseLight + SpecularLight;

						float3 Color = Color = lerp (Color1,Color2,saturate((FresnelTerm)*5.0f)*GlassMasks.a);
						//Color = Color2;
					#endif
				#endif
			#else

				CalculateLightingFromIBL( MaterialProps, LightingProps, EnvironmentMap, DiffuseIBL, SpecularIBL );
				CalculateShadowTerms( Input.WorldSpacePos, Shadows );
				CalculateSceneLights( Input.WorldSpacePos, Shadows, MaterialProps, DiffuseLight, SpecularLight );

				float3 Color = DiffuseIBL + SpecularIBL + DiffuseLight + SpecularLight;

			#endif
			//EK2 REFRACT

			float3 SssColor = vec3(0.0f);
			float SssMask = Properties.r;
			#ifdef FAKE_SSS_EMISSIVE
				float3 SkinColor = RGBtoHSV( Diffuse.rgb );
				SkinColor.z = 1.0f;
				SssColor = HSVtoRGB(SkinColor) * SssMask * 0.5f * MaterialProps._DiffuseColor;
				Color += SssColor;
			#endif

			//EK2 EMISSIVE SHADER
			//Use for emissive in normal BLUE channel.
			#ifdef EMISSIVE_NORMAL_BLUE

				float EmissiveStrength = 1.0f;
				float emissiveMask = PdxTex2D( NormalMap, Input.UV0 ).b;
				float3 emissiveColor = Diffuse.rgb * EmissiveStrength;
				Color = lerp(Color, emissiveColor, emissiveMask);

			#endif

			//Use for emissive in properties RED channel.
			#ifdef EMISSIVE_PROPERTIES_RED

				float EmissiveStrength = 1.0f;
				float emissiveMask = Properties.r;
				float3 emissiveColor = Diffuse.rgb * EmissiveStrength;
				Color = lerp(Color, emissiveColor, emissiveMask);
			#endif
			//EK2 EMISSIVE SHADER

			
			
			DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap, SssColor, SssMask );

			AddHoverHighlight( Color, Normal, LightingProps._ToCameraDir, HoverMult );	

			return Color;
		}

		// Remaps Value to [IntervalStart, IntervalEnd]
		// Assumes Value is in [0,1] and that 0 <= IntervalStart < IntervalEnd <= 1
		float RemapToInterval( float Value, float IntervalStart, float IntervalEnd )
		{
			return IntervalStart + Value * ( IntervalEnd - IntervalStart );
		}

		// The skin, eye and hair assets come with a special texture  (the "Color Mask", typically packed into 
		// another texture) that determines the Diffuse-PaletteColor blend. Artists also supply a remap interval 
		// used to bias this texture's values; essentially allowing the texture's full range of values to be 
		// mapped into a small interval of the diffuse lerp (e.g. [0.8, 1]).
		// If the texture value is 0.0, that is a special case indicating there shouldn't be any palette color, 
		// (it is used for non-hair things such as hair bands, earrings etc)
		float3 GetColorMaskColorBLend( float3 DiffuseColor, float3 PaletteColor, uint InstanceIndex, float ColorMaskStrength )
		{
			if ( ColorMaskStrength == 0.0 )
			{
				return DiffuseColor;
			}
			else
			{
				float2 Interval = GetColorMaskRemapInterval( InstanceIndex );
				float LerpTarget = RemapToInterval( ColorMaskStrength, Interval.x, Interval.y );
				return lerp( DiffuseColor.rgb, DiffuseColor.rgb * PaletteColor, LerpTarget );
			}
		}

		static const int USER_DATA_SELECTION_IDENTIFIER_OFFSET = 0;

		uint GetSelectionIdentifier( uint InstanceIndex )
		{
			return uint( Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + USER_DATA_SELECTION_IDENTIFIER_OFFSET ].x );
		}

		float4 GetUserData( uint InstanceIndex, int DataOffset )
		{
			return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + DataOffset ];
		}

		float2 MirrorOutsideUV( float2 UV )
		{
			if ( UV.x < 0.0 )
			{
				UV.x = -UV.x;
			}
			else if ( UV.x > 1.0 )
			{
				UV.x = 2.0 - UV.x;
			}
			if ( UV.y < 0.0 )
			{
				UV.y = -UV.y;
			}
			else if ( UV.y > 1.0 )
			{
				UV.y = 2.0 - UV.y;
			}
			return UV;
		}

		float2 TileUV( float2 UV )
		{
			UV *= 0.5f;
			UV = frac( UV );
			UV = UV * 2.0f;
			if ( UV.x > 1.0f )
			{
				UV.x = 2.0 - UV.x;
			}
			if ( UV.y > 1.0f )
			{
				UV.y = 2.0 - UV.y;
			}
			return UV;
		}

	]]

	#// Character shaders
	MainCode PS_skin
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 UV0 = Input.UV0;
				float4 Diffuse;
				float4 Properties;
				float3 NormalSample;

				//EK2
				float3 SkinColorPalette = vPaletteColorSkin.rgb;

				#ifdef SKIN_TO_HAIR_COLOR
				SkinColorPalette = vPaletteColorHair.rgb;
				#endif
				//END-EK2	

            #ifdef ENABLE_TEXTURE_OVERRIDE
                    Diffuse = PdxTex2D( DiffuseMapOverride, UV0 );
                    Properties = PdxTex2D( PropertiesMapOverride, UV0 );
                    NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMapOverride, UV0 ) );
            #else
				Diffuse = PdxTex2D( DiffuseMap, UV0 );
				Properties = PdxTex2D( PropertiesMap, UV0 );
				NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMap, UV0 ) );
			#endif


				//EK2

				float ColorMaskStrength = Diffuse.a;
				AddDecals( Diffuse, NormalSample, Properties, UV0, Input.InstanceIndex, 0, PreSkinColorDecalCount,0 );



				//Get the DecalData for the decal containing above colour in Mip6
				DecalData Data = GetDecalData(MAGENTA, DIFFUSE_DECAL, DecalCount);

				//Set Weight to be the transperancy/strength of the above decal
				float Weight = Data._Weight;

				SkinColorPalette = lerp(vPaletteColorSkin.rgb,vPaletteColorHair.rgb,Weight);


				//Diffuse.rgb = GetColorMaskColorBLend( Diffuse.rgb, vPaletteColorSkin.rgb, Input.InstanceIndex, ColorMaskStrength );
				Diffuse.rgb = GetColorMaskColorBLend( Diffuse.rgb, SkinColorPalette, Input.InstanceIndex, ColorMaskStrength );
				//END-EK2


				//EK2
				AddDecals( Diffuse, NormalSample, Properties, UV0, Input.InstanceIndex, PreSkinColorDecalCount, DecalCount,0 );
				//EK2

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, HoverMult );
				Out.Color = float4( Color, 1.0f );

				Out.SSAOColor = PdxTex2D( SSAOColorMap, UV0 );

				//EK2
				//Out.SSAOColor.rgb *= vPaletteColorSkin.rgb;
				Out.SSAOColor.rgb *= SkinColorPalette;
				//END-EK2
				return Out;
			}
			
		]]
	}
	
	MainCode PS_eye
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 UV0 = Input.UV0;
				float4 Diffuse = PdxTex2D( DiffuseMap, UV0 );
				float4 Properties = PdxTex2D( PropertiesMap, UV0 );
				float3 NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMap, UV0 ) );

				//EK2
				#ifdef EYE_DECAL

					float4 BaseDiffuse = Diffuse;

					AddDecals( Diffuse, NormalSample, Properties, UV0, Input.InstanceIndex, 0, PreSkinColorDecalCount, BODYPART_EYES);

					Diffuse.rgb = lerp(Diffuse,BaseDiffuse,BaseDiffuse.a).rgb;
				#endif
				

				float3 EyeColor = vPaletteColorEyes.rgb;

				#ifdef HSV_SHIFT
					EyeColor = RGBtoHSV(EyeColor);
					EyeColor.x = EyeColor.x + 0.5f;
					EyeColor = saturate(HSVtoRGB(EyeColor));
				#endif

				float ColorMaskStrength = Diffuse.a;

				#ifndef EYE_BLIND
				
					Diffuse.rgb = GetColorMaskColorBLend( Diffuse.rgb, EyeColor.rgb, Input.InstanceIndex, ColorMaskStrength );

					#ifdef EYE_DECAL
						AddDecals( Diffuse, NormalSample, Properties, UV0, Input.InstanceIndex, PreSkinColorDecalCount, DecalCount, BODYPART_EYES);
					#endif
					
				#endif
				//END-EK2


				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, 0.f );

				Out.Color = float4( Color, 1.0f );
				Out.SSAOColor = float4( vec3( 0.0f ), 1.0f );

				return Out;
			}
		]]
	}

	#EK2
		MainCode PS_skin_alpha
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 UV0 = Input.UV0;
				float4 Diffuse = PdxTex2D( DiffuseMap, UV0 );
				float4 Properties = PdxTex2D( PropertiesMap, UV0 );
				float3 NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMap, UV0 ) );

				float ColorMaskStrength = Diffuse.a;
				Diffuse.rgb = GetColorMaskColorBLend( Diffuse.rgb, vPaletteColorSkin.rgb, Input.InstanceIndex, ColorMaskStrength );

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, 0.f );

				Out.Color = float4( Color, 1.0f );
				Out.SSAOColor = float4( vec3( 0.0f ), 1.0f );

				return Out;
			}
		]]
	}
	#END-EK2

	MainCode PS_attachment
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;
				float2 UV0 = Input.UV0;
				float4 Diffuse = PdxTex2D( DiffuseMap, UV0 );
				float4 Properties = PdxTex2D( PropertiesMap, UV0 );
				float3 NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMap, UV0 ) );
				Properties.r = 1.0; // wipe this clean now, ready to be modified later
				Diffuse.a = PdxMeshApplyOpacity( Diffuse.a, Input.Position.xy, PdxMeshGetOpacity( Input.InstanceIndex ) );

				#ifdef VARIATIONS_ENABLED
					ApplyVariationPatterns( Input, Diffuse, Properties, NormalSample );

				//EK2
				#else
					#ifdef ATTACHEMENT_DECAY

					//Get the DecalData for the decal containing above colour in Mip6
					DecalData Data = GetDecalData(RED, DIFFUSE_DECAL, DecalCount);

					//Set Weight to be the transperancy/strength of the above decal
					float Weight = Data._Weight;
					uint DiffuseIndex = Data._DiffuseIndex;

					//R - WET MASK
					//G - THICK DIRT MASK
					//B - RUST MASK
					//A - WORN FABRIC MASK
					float4 DiffuseDecayMask2x = PdxTex2D( DecalDiffuseArray, float3( Input.UV0*2.0f, DiffuseIndex ) );
					float4 DiffuseDecayMask3x = PdxTex2D( DecalDiffuseArray, float3( Input.UV0*3.0f, DiffuseIndex ) );

					//RUST
					float3 RustMask = float3(0.4f,0.2f,0.13f);
					RustMask = RustMask * (DiffuseDecayMask3x.bbb);
					RustMask = Overlay( Diffuse.rgb, RustMask,1.0f );

					float ClothMask = smoothstep(1.0f-float(Properties.b*2.0f),1.0f-Properties.b,0.8f);
					float RustRoughness = DiffuseDecayMask2x.b*DiffuseDecayMask3x.b;

					Diffuse.rgb = lerp(Diffuse.rgb,RustMask,smoothstep(DiffuseDecayMask2x.b,DiffuseDecayMask2x.b+0.2f,Weight*0.8f)*ClothMask);
					Properties.a = lerp(Properties.a,1.0f,smoothstep(RustRoughness,RustRoughness+0.3f,Weight*0.4)*smoothstep(1.0f-float(Properties.a*2.0f),1.0f-Properties.a,0.8f)*ClothMask);

					// //Worn out fabrics
					 float FabricMask = saturate(0.6f-DiffuseDecayMask2x.a);

					 Diffuse.rgb = lerp(Diffuse.rgb,float3(0.9f,0.75f,0.6f),smoothstep(FabricMask,FabricMask+0.3f,(Weight*0.34f)*(1.0f-ClothMask)*0.7f));
					
					 Properties.b = lerp(Properties.b,0.0f,smoothstep(FabricMask,FabricMask+0.3f,(Weight*0.4f)*(1.0f-ClothMask)));
					 Properties.a = lerp(Properties.a,1.0f,smoothstep(FabricMask,FabricMask+0.3f,(Weight*0.4f)*(1.0f-ClothMask)));

					// //Holes in fabrics
					 float WearMask = abs(0.8f-DiffuseDecayMask2x.a);
					 Diffuse.a = lerp(Diffuse.a,0.0f,step(WearMask,Weight*0.3f)*(1.0f-ClothMask));

					// //Stains in fabric
					float StainMask = saturate(DiffuseDecayMask3x.r*5.0f);
					Diffuse.rgb = Multiply(Diffuse.rgb,float3(StainMask,StainMask,StainMask), clamp(Weight*2.0f,0.0f,1.0f));
					

					// //Layers of dirt
					 float DirtMask = clamp( NormalSample.b * NormalSample.b, 0, 1 );
					 DirtMask = max(DirtMask,DiffuseDecayMask3x.g*1.5);
					 float3 DirtDiffuse = float3(0.2f,0.1f,0.06f);
					
					 DirtDiffuse *= Diffuse.rgb;
					 Diffuse.rgb = lerp(Diffuse.rgb,DirtDiffuse,smoothstep(DirtMask*0.5f,DirtMask*1.5f,clamp(Weight*1.6f,0.0f,1.0f)));

					#endif
					//EK2

				#endif

				#ifdef USE_CHARACTER_DATA
				float AppliedHover = HoverMult;
				#else
					#ifdef VARIATIONS_ENABLED
					// see portrait_user_data.fxh - it explains data layout for userdata
					// we append hover value after _BodyPartIndex, so
					// it's a float under index 1 in float4 element of Data array
					// if portrait accessory use data layout changes, this will also break
					static const int USER_DATA_HOVER_SLOT = 9;
					float AppliedHover = GetUserData( Input.InstanceIndex, USER_DATA_HOVER_SLOT ).g;
					#else
					// if the effect doesn't have variations and is intended for a court artifact on a pedestal,
					// then hover data is the only thing set for the entity
					static const int USER_DATA_HOVER_SLOT = 0;
					float AppliedHover = GetUserData( Input.InstanceIndex, USER_DATA_HOVER_SLOT ).r;
					#endif
				#endif

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, AppliedHover );

				Out.Color = float4( Color, Diffuse.a );
				Out.SSAOColor = float4( vec3( 0.0f ), 1.0f );
				return Out;
			}
		]]
	}

	MainCode PS_portrait_hair_backface
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				return float4( vec3( 0.0f ), 1.0f );
			}
		]]
	}

	MainCode PS_hair
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 UV0 = Input.UV0;
				float4 Diffuse = PdxTex2D( DiffuseMap, UV0 );
				float4 Properties = PdxTex2D( PropertiesMap, UV0 );
				Properties *= vHairPropertyMult;
				float4 NormalSampleRaw = PdxTex2D( NormalMap, UV0 );
				float3 NormalSample = UnpackRRxGNormal( NormalSampleRaw ) * ( PDX_IsFrontFace ? 1 : -1 );

				float ColorMaskStrength = NormalSampleRaw.b;
				Diffuse.rgb = GetColorMaskColorBLend( Diffuse.rgb, vPaletteColorHair.rgb, Input.InstanceIndex, ColorMaskStrength );

				//EK2 - Salt n' Pepper
				#ifdef HAIR_AGING_DECAL

					//Get the DecalData for the decal containing above colour in Mip6
					DecalData Data = GetDecalData(GREEN, DIFFUSE_DECAL, DecalCount);

					//Get base hair texture
					float4 BaseDiffuse = PdxTex2D( DiffuseMap, UV0 );	

					//Set Weight to be the transperancy/strength of the above decal
					float Weight = Data._Weight;

					//Interpolate between the original white hair texture and the final coloured texture using Weight as strength value to create salt and pepper effect.
					Diffuse.rgb = lerp (Diffuse.rgb, BaseDiffuse.ggg, step((1.0f - Weight) , saturate(BaseDiffuse.r)) * Diffuse.a * (Weight ) * 0.7f);	

				#endif	
				//END-EK2

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, HoverMult );

				#ifdef ALPHA_TO_COVERAGE
					Diffuse.a = RescaleAlphaByMipLevel( Diffuse.a, UV0, DiffuseMap );

					const float CUTOFF = 0.5f;
					Diffuse.a = SharpenAlpha( Diffuse.a, CUTOFF );
				#endif

				#ifdef WRITE_ALPHA_ONE
					Out.Color = float4( Color, 1.0f );
				#else
					#ifdef HAIR_TRANSPARENCY_HACK
						// TODO [HL]: Hack to stop clothing fragments from being discarded by transparent hair,
						// proper fix is to ensure that hair is drawn after clothes
						// https://beta.paradoxplaza.com/browse/PSGE-3103
						clip( Diffuse.a - 0.5f );
					#endif

					Out.Color = float4( Color, Diffuse.a );
				#endif

				Out.SSAOColor = float4( vec3( 0.0f ), 1.0f );

				return Out;
			}
		]]
	}

	MainCode PS_hair_double_sided
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 UV0 = Input.UV0;
				float4 Diffuse = PdxTex2D( DiffuseMap, UV0 );
				#ifdef ALPHA_TEST
				clip( Diffuse.a - 0.5f );
				Diffuse.a = 1.0f;
				#endif
				float4 Properties = PdxTex2D( PropertiesMap, UV0 );
				float3 NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMap, UV0 ) );

				Properties *= vHairPropertyMult;
				Diffuse.rgb *= vPaletteColorHair.rgb;

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, HoverMult );

				Out.Color = float4( Color, Diffuse.a );
				Out.SSAOColor = float4( vec3( 0.0f ), 1.0f );

				return Out;
			}
		]]
	}

	#MOD-HAIR-BLEND
	MainCode PS_skin_hair_eye_blend
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 UV0 = Input.UV0;
				float4 Diffuse = PdxTex2D( DiffuseMap, UV0 );
				float4 Properties = PdxTex2D( PropertiesMap, UV0 );
				Properties *= vHairPropertyMult;
				float4 NormalSampleRaw = PdxTex2D( NormalMap, UV0 );
				float3 NormalSample = UnpackRRxGNormal( NormalSampleRaw ) * ( PDX_IsFrontFace ? 1 : -1 );

				float4 ColorMask = PdxTex2D( SSAOColorMap, UV0 );
				float3 ColorPalette = float3(0.0f,0.0f,0.0f);

				ColorPalette = lerp(ColorPalette,vPaletteColorSkin.rgb,ColorMask.r);
				ColorPalette = lerp(ColorPalette,vPaletteColorHair.rgb,ColorMask.g);
				ColorPalette = lerp(ColorPalette,vPaletteColorEyes.rgb,ColorMask.b);

				ColorMask.a = max(max(ColorMask.r,ColorMask.g),ColorMask.b);

				Diffuse.rgb = GetColorMaskColorBLend( Diffuse.rgb, ColorPalette, Input.InstanceIndex, ColorMask.a );



				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, HoverMult );

				#ifdef ALPHA_TO_COVERAGE
					Diffuse.a = RescaleAlphaByMipLevel( Diffuse.a, UV0, DiffuseMap );

					const float CUTOFF = 0.5f;
					Diffuse.a = SharpenAlpha( Diffuse.a, CUTOFF );
				#endif

				#ifdef WRITE_ALPHA_ONE
					Out.Color = float4( Color, 1.0f );
				#else
					#ifdef HAIR_TRANSPARENCY_HACK
						// TODO [HL]: Hack to stop clothing fragments from being discarded by transparent hair,
						// proper fix is to ensure that hair is drawn after clothes
						// https://beta.paradoxplaza.com/browse/PSGE-3103
						clip( Diffuse.a - 0.5f );
					#endif

					Out.Color = float4( Color, Diffuse.a );
				#endif

				Out.SSAOColor = float4( vec3( 0.0f ), 1.0f );

				return Out;
			}
		]]
	}

	#END-MOD


	MainCode PS_court_selection
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_OUTPUT_SELECTION"
		Code
		[[
			PDX_MAIN
			{
				PS_OUTPUT_SELECTION Out;
				Out.Identifier = GetSelectionIdentifier( Input.InstanceIndex );
				if ( Out.Identifier == 0 )
				{
					discard;
				}
				return Out;
			}
		]]
	}

	MainCode PS_court_selection_backfacing
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "void"
		Code
		[[
			PDX_MAIN
			{
			}
		]]
	}

	#// Main court asset shader
	MainCode PS_court
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			#ifndef PROPERTIES_UV_SET
				#define PROPERTIES_UV_SET Input.UV0
			#endif
			#ifndef NORMAL_UV_SET
				#define NORMAL_UV_SET Input.UV0
			#endif
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				#if defined( COA ) || defined( USER_COLOR )
					static const int USER_DATA_PRIMARY_COLOR = 0;
					static const int USER_DATA_SECONDARY_COLOR = 1;
					static const int USER_DATA_ATLAS_SLOT = 2;
					static const int USER_DATA_HOVER_SLOT = 3;
				#else
					static const int USER_DATA_HOVER_SLOT = 0;
				#endif

				float4 Properties = PdxTex2D( PropertiesMap, Input.UV0 );

				float3 UserColor = float3( 1.0f, 1.0f, 1.0f );
				#if defined( USER_COLOR )
					float3 UserColor1 = GetUserData( Input.InstanceIndex, USER_DATA_PRIMARY_COLOR ).rgb;
					float3 UserColor2 = GetUserData( Input.InstanceIndex, USER_DATA_SECONDARY_COLOR ).rgb;

					UserColor = lerp( UserColor, UserColor1, Properties.r );
					UserColor = lerp( UserColor, UserColor2, PdxTex2D( NormalMap, NORMAL_UV_SET ).b );
				#endif
				#if defined( COA )
					float4 CoAAtlasSlot = GetUserData( Input.InstanceIndex, USER_DATA_ATLAS_SLOT );

					// Primitive method to tile a non-tiled texture
					Input.UV1 = TileUV( Input.UV1 );

					// Fix for seam artifacts in atlas texture
					CoAAtlasSlot.xy += 0.0003f;
					CoAAtlasSlot.zw -= 0.0006f;

					// CoA Atlas UV
					float2 AtlasUV = Input.UV1 * CoAAtlasSlot.zw;
					float2 FlagCoords = CoAAtlasSlot.xy + AtlasUV;

					// Primary and secondary color grab
					float3 PrimaryColor = GetUserData( Input.InstanceIndex, USER_DATA_PRIMARY_COLOR ).rgb;
					float3 SecondaryColor = GetUserData( Input.InstanceIndex, USER_DATA_SECONDARY_COLOR ).rgb;

					// Blend
					float3 CoAColor = lerp( PrimaryColor, PdxTex2D( PatternMask, FlagCoords ).rgb, Properties.g );
					UserColor = lerp( UserColor, CoAColor, Properties.r );
				#endif

				float4 Diffuse = PdxTex2D( DiffuseMap, Input.UV0 );
				#if defined( PDX_MESH_UV1 ) && defined( TILING_AO )
					Diffuse.rgb *= PdxTex2D( DiffuseMap, Input.UV1 ).a;
					Diffuse.a = 1.0f;
				#endif

				Diffuse.a = PdxMeshApplyOpacity( Diffuse.a, Input.Position.xy, PdxMeshGetOpacity( Input.InstanceIndex ) );
				Diffuse.rgb *= UserColor;

				float3 NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMap, Input.UV0 ) );

				Properties.g = 0.16f;	// Fixed specular mesh value /JR
				float HoverMult = GetUserData( Input.InstanceIndex, USER_DATA_HOVER_SLOT ).r;
				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input, HoverMult );

				#ifdef ALPHA_TO_COVERAGE
					Diffuse.a = RescaleAlphaByMipLevel( Diffuse.a, Input.UV0, DiffuseMap );
					const float CUTOFF = 0.5f;
					Diffuse.a = SharpenAlpha( Diffuse.a, CUTOFF );
				#endif

				#if defined( EMISSIVE )
					float emissiveMask = PdxTex2D( NormalMap, Input.UV0 ).b;
					float3 emissiveColor = Diffuse.rgb * EmissiveStrength;
					Color = lerp(Color, emissiveColor, emissiveMask);
				#endif

				Out.Color = float4( Color, Diffuse.a );
				Out.SSAOColor = float4( 0.0f, 0.0f, 0.0f, Diffuse.a );

				return Out;
			}
		]]
	}

	# MOD(court-skybox)
	MainCode PS_SKYX_court_sky
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				float3 FromCameraDir = normalize(Input.WorldSpacePos - CameraPosition);
				float3 CubemapSample = PdxTexCube(EnvironmentMap, FromCameraDir).rgb;

				PS_COLOR_SSAO Out;
				Out.Color     = float4(CubemapSample, 1.0);
				Out.SSAOColor = float4(1.0, 1.0, 1.0, 1.0);

				return Out;
			}
		]]
	}
	# END MOD

	MainCode PS_noop
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				return float4( vec3( 0.0f ), 1.0f );
			}
		]]
	}
}

BlendState hair_alpha_blend
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	SourceAlpha = "ONE"
	DestAlpha = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE|ALPHA"
}

DepthStencilState hair_alpha_blend
{
	DepthWriteEnable = no
}

BlendState alpha_to_coverage
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE|ALPHA"
	SourceAlpha = "ONE"
	DestAlpha = "INV_SRC_ALPHA"
	AlphaToCoverage = yes
}

RasterizerState rasterizer_no_culling
{
	CullMode = "none"
}

RasterizerState rasterizer_backfaces
{
	FrontCCW = yes
}
RasterizerState ShadowRasterizerState
{
	#Don't go higher than 10000 as it will make the shadows fall through the mesh
	DepthBias = 500
	SlopeScaleDepthBias = 2
}
RasterizerState ShadowRasterizerStateBackfaces
{
	DepthBias = 1000
	SlopeScaleDepthBias = 2
	FrontCCW = yes
}

Effect portrait_skin
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin"
	Defines = { "FAKE_SSS_EMISSIVE" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_teeth
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin"
	Defines = { "FAKE_SSS_EMISSIVE" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_skin_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_teeth_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_skinShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_skin_face
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin"
	Defines = { "FAKE_SSS_EMISSIVE" "ENABLE_TEXTURE_OVERRIDE" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_skin_face_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_skin_faceShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_eye
{
	VertexShader = "VS_standard"
	PixelShader = "PS_eye"
	Defines = { "EMISSIVE_PROPERTIES_RED" "EYE_DECAL" "PDX_MESH_BLENDSHAPES"}
}

Effect portrait_eye_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = { "USE_CHARACTER_DATA" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PDX_MESH_BLENDSHAPES"}

}

Effect portrait_attachment_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachmentShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_pattern
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = { "VARIATIONS_ENABLED" "USE_CHARACTER_DATA" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PDX_MESH_BLENDSHAPES"}
}

Effect portrait_attachment_pattern_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_patternShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_pattern_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = { "VARIATIONS_ENABLED" "USE_CHARACTER_DATA" "PDX_MESH_BLENDSHAPES" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY"}
}

Effect portrait_attachment_pattern_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_pattern_alpha_to_coverageShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = { "USE_CHARACTER_DATA" "PDX_MESH_BLENDSHAPES" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY"}
}

Effect portrait_attachment_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_alpha_to_coverageShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_with_coa
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	Defines = { "COA_ENABLED" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_with_coa_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	Defines = { "COA_ENABLED" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_with_coaShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_with_coa_and_variations
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	Defines = { "COA_ENABLED" "VARIATIONS_ENABLED" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_with_coa_and_variations_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	Defines = { "COA_ENABLED" "VARIATIONS_ENABLED" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_with_coa_and_variationsShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_hair
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	BlendState = "alpha_to_coverage"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "ALPHA_TO_COVERAGE" "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL" }
}

Effect portrait_hair_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_hair_transparency_hack
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	BlendState = "alpha_to_coverage"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "HAIR_TRANSPARENCY_HACK" "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_transparency_hack_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	BlendState = "alpha_to_coverage"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "HAIR_TRANSPARENCY_HACK" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_hair_double_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair_double_sided"
	BlendState = "alpha_to_coverage"
	#DepthStencilState = "test_and_write"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL" }
}

Effect portrait_hair_double_sided_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_hair_alpha
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	BlendState = "hair_alpha_blend"
	DepthStencilState = "hair_alpha_blend"
	Defines = { "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_alpha_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_double_sided_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_hair_opaque
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	
	Defines = { "WRITE_ALPHA_ONE" "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_opaque_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_alpha
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "hair_alpha_blend"
	DepthStencilState = "hair_alpha_blend"
	Defines = { "USE_CHARACTER_DATA" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_alphaShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_hair_backside
{
	VertexShader = "VS_standard"
	PixelShader = "PS_portrait_hair_backface"
	RasterizerState = "rasterizer_backfaces"
	Defines = { "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_backside_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection_backfacing"
	RasterizerState = "rasterizer_backfaces"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect court
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"

	Defines = { "EMISSIVE" }
}

Effect court_no_shadow
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"

	Defines = { "EMISSIVE" }
}

Effect court_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"

	BlendState = "alpha_to_coverage"
	Defines = { "EMISSIVE" "ALPHA_TO_COVERAGE" }
}

Effect court_gemcube
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"

	Defines = { "EMISSIVE" "GEMCUBE" }
}
Effect court_gemcube_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"

	BlendState = "alpha_to_coverage"
	Defines = { "EMISSIVE" "GEMCUBE" "ALPHA_TO_COVERAGE" }
}

Effect court_usercolor
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"

	Defines = { "USER_COLOR" }
}

Effect court_usercolor_coa
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"

	Defines = { "USER_COLOR" "COA" }
}

Effect courtShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = ShadowRasterizerState
}

Effect court_usercolorShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = ShadowRasterizerState
}

Effect court_usercolor_coaShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = ShadowRasterizerState
}

Effect court_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect court_no_shadow_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect court_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect court_gemcube_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect court_gemcube_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect court_usercolor_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect court_usercolor_coa_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect portrait_artifact_pattern
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	Defines = { "VARIATIONS_ENABLED" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_pattern_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_patternShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_alpha_to_coverageShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_pattern_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = { "VARIATIONS_ENABLED" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_pattern_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_artifact_pattern_alpha_to_coverageShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

# Effects from pdx_mesh.shader
# Those are never supposed to run, they only here so the shader compiler has something to compile for each render pass

Effect standard_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect snap_to_terrain_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_atlas_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_atlas_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor_coa_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect sine_flag_animation_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect selection_marker_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect material_test_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_winter_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor_winter_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_selection_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_atlas_selection_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_atlas_selection_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"
}

Effect standard_atlas
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_atlas_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor_alpha
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor_alpha_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor_winter
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_usercolor_coa
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_winter
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_alpha_to_coverage_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_alpha_to_coverage_winter
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect standard_alpha_to_coverage_winter_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_atlas
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_atlas_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_atlas_usercolor
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_atlas_usercolor_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect material_test
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court"
}

Effect selection_marker
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect sine_flag_animation
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

#EK2
Effect skin_alpha
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin_alpha"
}

Effect skin_alpha_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect portrait_skin_hair_color
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin"
	Defines = { "FAKE_SSS_EMISSIVE" "SKIN_TO_HAIR_COLOR" "PDX_MESH_BLENDSHAPES"}
}



Effect portrait_skin_hair_color_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
}

Effect EK2_snap_to_terrain
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect EK2_snap_to_terrain_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect EK2_snap_to_terrain_selection_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect EK2_snap_to_terrain_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_selection_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect snap_to_terrain_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect EK2_county_overlay
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect EK2_county_overlay_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect EK2_county_overlay_selection_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect EK2_county_overlay_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect portrait_eye_no_decal
{
	VertexShader = "VS_standard"
	PixelShader = "PS_eye"
	Defines = { "EMISSIVE_PROPERTIES_RED" "PDX_MESH_BLENDSHAPES"}
}

Effect portrait_eye_shift
{
	VertexShader = "VS_standard"
	PixelShader = "PS_eye"
	Defines = { "EMISSIVE_PROPERTIES_RED" "EYE_DECAL" "HSV_SHIFT" "PDX_MESH_BLENDSHAPES"}
}

Effect portrait_eye_blind
{
	VertexShader = "VS_standard"
	PixelShader = "PS_eye"
	Defines = { "EYE_DECAL" "EYE_BLIND" "PDX_MESH_BLENDSHAPES"}
}

Effect portrait_eye_no_decal_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_eye_shift_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }

}

Effect portrait_eye_blind_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_glass
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "hair_alpha_blend"
	#DepthStencilState = "hair_alpha_blend"
	Defines = { "USE_CHARACTER_DATA" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PDX_MESH_BLENDSHAPES" "PARALLAX" "REFRACT"}
}

Effect portrait_attachment_glass_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_pattern_glass
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "hair_alpha_blend"
	#DepthStencilState = "hair_alpha_blend"
	Defines = { "VARIATIONS_ENABLED" "USE_CHARACTER_DATA" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PDX_MESH_BLENDSHAPES" "PARALLAX" "REFRACT"}
}

Effect portrait_attachment_pattern_glass_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

#END-EK2

# MOD(court-skybox)
Effect SKYX_court_sky
{
	VertexShader = "VS_standard"
	PixelShader = "PS_SKYX_court_sky"
}

Effect SKYX_court_sky_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_SKYX_court_sky"
}

# Same as SKYX_court_sky, included for backwards compatibility
Effect COOP_court_sky
{
	VertexShader = "VS_standard"
	PixelShader = "PS_SKYX_court_sky"
}

# Same as SKYX_court_sky_selection, included for backwards compatibility
Effect COOP_court_sky_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_SKYX_court_sky"
}
# END MOD

# MOD(map-skybox)
# The following effects are not used but need to be defined here to suppress errors

Effect SKYX_sky
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect SKYX_sky_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect SKYX_sky_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect SKYX_sky_selection_mapobject
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}

Effect skybox_attachment
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}
Effect skybox_attachment_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_noop"
}
# END MOD


Effect portrait_color_blend
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin_hair_eye_blend"
	BlendState = "alpha_to_coverage"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "ALPHA_TO_COVERAGE" "PDX_MESH_BLENDSHAPES" "EMISSIVE_PROPERTIES_RED"}
}

Effect portrait_color_blend_selection
{
	VertexShader = "VS_standard"
	PixelShader = "PS_court_selection"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "PDX_MESH_BLENDSHAPES" "EMISSIVE_PROPERTIES_RED"}
}
