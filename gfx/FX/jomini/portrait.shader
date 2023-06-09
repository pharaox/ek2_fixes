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
	TextureSampler CoaTexture 
	{
		Index = 12
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
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
	}



	VertexStruct PS_COLOR_SSAO
	{
		float4 Color : PDX_COLOR0;
		float4 SSAOColor : PDX_COLOR1;
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
	float4 	ShadowProj		: TEXCOORD7;
	# This instance index is used to fetch custom user data from the Data[] array (see pdxmesh.fxh)
	uint 	InstanceIndex	: TEXCOORD8;
};

VertexStruct VS_INPUT_PDXMESHSTANDARD_ID
{
    float3 Position			: POSITION;
	float3 Normal      		: TEXCOORD0;
	float4 Tangent			: TEXCOORD1;
	float2 UV0				: TEXCOORD2;
@ifdef PDX_MESH_UV1     	
	float2 UV1				: TEXCOORD3;
@endif
@ifdef PDX_MESH_UV2
	float2 UV2				: TEXCOORD4;
@endif


	uint2 InstanceIndices 	: TEXCOORD5;
	
@ifdef PDX_MESH_SKINNED
	uint4 BoneIndex 		: TEXCOORD6;
	float3 BoneWeight		: TEXCOORD7;
@endif

	uint VertexID			: PDX_VertexID;
};

# Portrait constants (SPortraitConstants)
ConstantBuffer( 5 )
{
	float4 		vPaletteColorSkin;
	float4 		vPaletteColorEyes;
	float4 		vPaletteColorHair;
	float4		vSkinPropertyMult;
	float4		vEyesPropertyMult;
	float4		vHairPropertyMult;
	
	float4 		Light_Color_Falloff[3];
	float4 		Light_Position_Radius[3]
	float4 		Light_Direction_Type[3];
	float4 		Light_InnerCone_OuterCone_AffectedByShadows[3];
	
	int			DecalCount;
	int         PreSkinColorDecalCount
	int			TotalDecalCount;
	int 		_; // Alignment

	float4 		PatternColorOverrides[16];

	float		HasDiffuseMapOverride;
	float		HasNormalMapOverride;
	float		HasPropertiesMapOverride;
};
Code
[[
	#define LIGHT_COUNT 3
	#define LIGHT_TYPE_NONE 0
	#define LIGHT_TYPE_DIRECTIONAL 1
	#define LIGHT_TYPE_SPOTLIGHT 2
	#define LIGHT_TYPE_POINTLIGHT 3
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
	
	MainCode VS_portrait_blend_shapes
	{
		Input = "VS_INPUT_PDXMESHSTANDARD_ID"
		Output = "VS_OUTPUT_PDXMESHPORTRAIT"
		Code
		[[
			PDX_MAIN
			{
			  	VS_OUTPUT_PDXMESHPORTRAIT Out;
				
				float4 vPosition = float4( Input.Position.xyz, 1.0f );
				float3 vBlendPositionDiff;
				float3 vBlendNormalDiff;
				float3 vBlendTangentDiff;
				ProcessBlendShapes( vBlendPositionDiff, vBlendNormalDiff, vBlendTangentDiff, Input.VertexID );
				vPosition.xyz += vBlendPositionDiff;
				
				float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
			#ifdef PDX_MESH_SKINNED
				float4 vSkinnedPosition = float4( 0, 0, 0, 0 );
				float3 vSkinnedNormal = float3( 0, 0, 0 );
				float3 vSkinnedTangent = float3( 0, 0, 0 );
				float3 vSkinnedBitangent = float3( 0, 0, 0 );
			
				float4 vWeight = float4( Input.BoneWeight.xyz, 1.0f - Input.BoneWeight.x - Input.BoneWeight.y - Input.BoneWeight.z );
			
				for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
			    {
					int nIndex = int( Input.BoneIndex[i] );
					float4x4 mat = BoneMatrices[nIndex + Input.InstanceIndices.x];
					vSkinnedPosition += mul( mat, vPosition ) * vWeight[i];

					float3x3 NormalTransform = CastTo3x3( BoneNormalMatrices[ nIndex + Input.InstanceIndices.x ] );
			
					float3 vNormal = mul( NormalTransform, Input.Normal + vBlendNormalDiff );
					float3 vTangent = mul( NormalTransform, Input.Tangent.xyz + vBlendTangentDiff );
					float3 vBitangent = cross( vNormal, vTangent ) * Input.Tangent.w;
			
					vSkinnedNormal += vNormal * vWeight[i];
					vSkinnedTangent += vTangent * vWeight[i];
					vSkinnedBitangent += vBitangent * vWeight[i];
				}
			
				Out.Position = mul( WorldMatrix, vSkinnedPosition );
				
				Out.Normal = normalize( mul( CastTo3x3(WorldMatrix), normalize( vSkinnedNormal ) ) );
				Out.Tangent = normalize( mul( CastTo3x3(WorldMatrix), normalize( vSkinnedTangent ) ) );
				Out.Bitangent = normalize( mul( CastTo3x3(WorldMatrix), normalize( vSkinnedBitangent ) ) );
			#else
				Out.Position = mul( WorldMatrix, vPosition );
				
				Out.Normal = normalize( mul( CastTo3x3( WorldMatrix ), Input.Normal + vBlendNormalDiff ) );
				Out.Tangent = normalize( mul( CastTo3x3( WorldMatrix ), Input.Tangent.xyz + vBlendTangentDiff ) );
				Out.Bitangent = normalize( cross( Out.Normal, Out.Tangent ) * Input.Tangent.w);
			#endif
			
				Out.WorldSpacePos.xyz = Out.Position.xyz;
				Out.WorldSpacePos /= WorldMatrix[3][3];
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, Out.Position );
				
				Out.ShadowProj = mul( ShadowMapTextureMatrix, float4( Out.WorldSpacePos, 1.0 ) );
				
				Out.UV0 = Input.UV0;
			#ifdef PDX_MESH_UV1
				Out.UV1 = Input.UV1;
			#else
				Out.UV1 = vec2( 0.0 );
			#endif
			#ifdef PDX_MESH_UV2
				Out.UV2 = Input.UV2;
			#else
				Out.UV2 = vec2( 0.0 );
			#endif
				Out.InstanceIndex = Input.InstanceIndices.y;
				return Out;
			}
		]]
	}

	MainCode VS_portrait_blend_shapes_shadow
	{
		Input = "VS_INPUT_PDXMESHSTANDARD_ID"
		Output = "VS_OUTPUT_PDXMESHSHADOWSTANDARD"
		Code
		[[
			PDX_MAIN
			{
			  	VS_OUTPUT_PDXMESHSHADOWSTANDARD Out;
				
				float4 vPosition = float4( Input.Position.xyz, 1.0 );
				float3 vBlendPositionDiff;
				ProcessBlendShapesPositionOnly( vBlendPositionDiff, Input.VertexID );
				vPosition.xyz += vBlendPositionDiff;
				
				float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
			#ifdef PDX_MESH_SKINNED
				float4 vSkinnedPosition = float4( 0, 0, 0, 0 );
			
				float4 vWeight = float4( Input.BoneWeight.xyz, 1.0f - Input.BoneWeight.x - Input.BoneWeight.y - Input.BoneWeight.z );
				for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
			    {
					int nIndex = int( Input.BoneIndex[i] );
					float4x4 mat = BoneMatrices[nIndex + Input.InstanceIndices.x];
					vSkinnedPosition += mul( mat, vPosition ) * vWeight[i];
				}
				Out.Position = mul( WorldMatrix, vSkinnedPosition );
			#else
				Out.Position = mul( WorldMatrix, vPosition );
			#endif
			
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, Out.Position );
				Out.UV_InstanceIndex = float3( Input.UV0, Input.InstanceIndices.y );
				return Out;
			}
		]]
	}
	
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

				#ifdef SKYBOX
					float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Out.InstanceIndex );
					float4x4 InvWorldMatrix = transpose( WorldMatrix );
					//Out.WorldSpacePos = mul (InvWorldMatrix,Out.WorldSpacePos);
					Out.WorldSpacePos = mul (InvViewMatrix,Out.WorldSpacePos);
					//float3 Scale =  float3(GetMatrixData( ViewMatrix, 0, 1 ), GetMatrixData( ViewMatrix, 1, 1 ), GetMatrixData( ViewMatrix, 2, 1 ));

					float3 CameraVector = normalize(Out.WorldSpacePos - CameraPosition);
					Out.WorldSpacePos = Out.WorldSpacePos + CameraVector * 200.0f;
					Out.WorldSpacePos.y += 100.0f;
					//float4 Offset = ViewMatrix[3]-WorldMatrix[3];
					//Out.WorldSpacePos += Offset.xyz;

					//float4x4 mat = 1.0f;
					//mat[3] = ViewMatrix[3];
					//Out.WorldSpacePos -= Scale;

					Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos, 1.0f ) );	
				#endif
				
				return Out;
			}
		]]
	}
}

PixelShader =
{
	Code
	[[
		struct SPortraitPointLight
		{
			float3 _Position;
			float _Radius;
			float3 _Color;
			float _Falloff;
		};
		struct SPortraitSpotLight
		{
			SPortraitPointLight	_PointLight;
			float3 _ConeDirection;
			float _ConeInnerCosAngle;
			float _ConeOuterCosAngle;
		};

		SPortraitPointLight GetPortraitPointLight( float4 PositionAndRadius, float4 ColorAndFalloff )
		{
			SPortraitPointLight PointLight;
			PointLight._Position = PositionAndRadius.xyz;
			PointLight._Radius = PositionAndRadius.w;
			PointLight._Color = ColorAndFalloff.xyz;
			PointLight._Falloff = ColorAndFalloff.w;
			return PointLight;
		}
	
		SPortraitSpotLight GetPortraitSpotLight( float4 PositionAndRadius, float4 ColorAndFalloff, float3 Direction, float InnerCosAngle, float OuterCosAngle )
		{
			SPortraitSpotLight Ret;
			Ret._PointLight = GetPortraitPointLight( PositionAndRadius, ColorAndFalloff );
			Ret._ConeDirection = Direction;
			Ret._ConeInnerCosAngle = InnerCosAngle;
			Ret._ConeOuterCosAngle = OuterCosAngle;
			return Ret;
		}
		
		void GGXPointLight( SPortraitPointLight Pointlight, float3 WorldSpacePos, float ShadowTerm, SMaterialProperties MaterialProps, inout float3 DiffuseLightOut, inout float3 SpecularLightOut )
		{
			float3 PosToLight = Pointlight._Position - WorldSpacePos;
			float DistanceToLight = length( PosToLight );

			float LightIntensity = CalcLightFalloff( Pointlight._Radius, DistanceToLight, Pointlight._Falloff );
			if ( LightIntensity > 0.0 )
			{
				SLightingProperties LightingProps;
				LightingProps._ToCameraDir = normalize( CameraPosition - WorldSpacePos );
				LightingProps._ToLightDir = PosToLight / DistanceToLight;
				LightingProps._LightIntensity = Pointlight._Color * LightIntensity;
				LightingProps._ShadowTerm = ShadowTerm;
				LightingProps._CubemapIntensity = 0.0;
				LightingProps._CubemapYRotation = Float4x4Identity();
				
				float3 DiffuseLight;
				float3 SpecularLight;
				CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				DiffuseLightOut += DiffuseLight;
				SpecularLightOut += SpecularLight;
			}
		}
		
		void GGXSpotLight( SPortraitSpotLight Spot, float3 WorldSpacePos, float ShadowTerm, SMaterialProperties MaterialProps, inout float3 DiffuseLightOut, inout float3 SpecularLightOut )
		{
			float3 	PosToLight = Spot._PointLight._Position - WorldSpacePos;
			float 	DistanceToLight = length(PosToLight);
			float3	ToLightDir = PosToLight / DistanceToLight;
			
			float LightIntensity = CalcLightFalloff( Spot._PointLight._Radius, DistanceToLight, Spot._PointLight._Falloff );
			float PdotL = dot( -ToLightDir, Spot._ConeDirection );
			LightIntensity *= smoothstep( Spot._ConeOuterCosAngle, Spot._ConeInnerCosAngle, PdotL );
			if ( LightIntensity > 0.0 )
			{
				SLightingProperties LightingProps;
				LightingProps._ToCameraDir = normalize( CameraPosition - WorldSpacePos );
				LightingProps._ToLightDir = ToLightDir;
				LightingProps._LightIntensity = Spot._PointLight._Color * LightIntensity;
				LightingProps._ShadowTerm = ShadowTerm;
				LightingProps._CubemapIntensity = 0.0;
				LightingProps._CubemapYRotation = Float4x4Identity();
				
				float3 DiffuseLight;
				float3 SpecularLight;
				CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				DiffuseLightOut += DiffuseLight;
				SpecularLightOut += SpecularLight;
			}
		}

		void CalculatePortraitLights( float3 WorldSpacePos, float ShadowTerm, SMaterialProperties MaterialProps, inout float3 DiffuseLightOut, inout float3 SpecularLightOut )
		{
			for( int i = 0; i < LIGHT_COUNT; ++i )
			{
				float3 DiffuseLight = vec3(0);
				float3 SpecularLight = vec3(0);
				
				//Scale color by ShadowTerm
				float4 Color_Fallof = Light_Color_Falloff[i];
				float LightShadowTerm = Light_InnerCone_OuterCone_AffectedByShadows[i].z > 0.5 ? ShadowTerm : 1.0;
				
				if( Light_Direction_Type[i].w == LIGHT_TYPE_SPOTLIGHT )
				{
					float InnerAngle = Light_InnerCone_OuterCone_AffectedByShadows[i].x;
					float OuterAngle = Light_InnerCone_OuterCone_AffectedByShadows[i].y;
					SPortraitSpotLight Spot = GetPortraitSpotLight( Light_Position_Radius[i], Color_Fallof, Light_Direction_Type[i].xyz, InnerAngle, OuterAngle );
					GGXSpotLight( Spot, WorldSpacePos, LightShadowTerm, MaterialProps, DiffuseLight, SpecularLight );
				}
				else if( Light_Direction_Type[i].w == LIGHT_TYPE_POINTLIGHT )
				{
					SPortraitPointLight Light = GetPortraitPointLight( Light_Position_Radius[i], Color_Fallof );
					GGXPointLight( Light, WorldSpacePos, LightShadowTerm, MaterialProps, DiffuseLight, SpecularLight );
				}
				else if( Light_Direction_Type[i].w == LIGHT_TYPE_DIRECTIONAL )
				{
					SLightingProperties LightingProps;
					LightingProps._ToCameraDir = normalize( CameraPosition - WorldSpacePos );
					LightingProps._ToLightDir = -Light_Direction_Type[i].xyz;
					LightingProps._LightIntensity = Color_Fallof.rgb;
					LightingProps._ShadowTerm = LightShadowTerm;
					LightingProps._CubemapIntensity = 0.0;
					LightingProps._CubemapYRotation = Float4x4Identity();

					CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				}
				
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


		

		float3 CommonPixelShader( float4 Diffuse, float4 Properties, float3 NormalSample, in VS_OUTPUT_PDXMESHPORTRAIT Input )
		{
			float3x3 TBN = Create3x3( normalize( Input.Tangent ), normalize( Input.Bitangent ), normalize( Input.Normal ) );
			float3 Normal = normalize( mul( NormalSample, TBN ) );
			
			SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, saturate( Properties.a ), Properties.g, Properties.b );
			SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowTexture );

			//EK2
			float3 DiffuseIBL = vec3(0.0);
			float3 SpecularIBL = vec3(0.0);
			float3 DiffuseLight = vec3(0.0);
			float3 SpecularLight = vec3(0.0);

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
					CalculatePortraitLights( Input.WorldSpacePos, LightingPropsRefract._ShadowTerm, MaterialPropsRefract, DiffuseLight, SpecularLight );

					float3 Lighting = DiffuseIBL + SpecularIBL + DiffuseLight + SpecularLight;
					Albedo1.rgb = lerp (Albedo1.rgb, Albedo1.rgb * 3.0f, Lighting);

					#if !defined(PARALLAX) || defined(PDX_OPENGL)
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
				#if defined(PARALLAX) && !defined(PDX_OPENGL)

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
					CalculatePortraitLights( Input.WorldSpacePos, LightingPropsParallax._ShadowTerm, MaterialPropsParallax, DiffuseLight, SpecularLight );

					

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
				CalculatePortraitLights( Input.WorldSpacePos, LightingProps._ShadowTerm, MaterialProps, DiffuseLight, SpecularLight );

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







			Color = ApplyDistanceFog( Color, Input.WorldSpacePos );
			
			DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap, SssColor, SssMask );			
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
	]]

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

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input );
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
	
				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input );
				Out.Color = float4( Color, 1.0f );
				
				Out.SSAOColor = PdxTex2D( SSAOColorMap, UV0 );
				Out.SSAOColor.rgb *= vPaletteColorEyes.rgb;
	
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
				
				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input );
				Out.Color = float4( Color, 1.0f );
				
				Out.SSAOColor = PdxTex2D( SSAOColorMap, UV0 );
				Out.SSAOColor.rgb *= vPaletteColorSkin.rgb;
	
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

					//Worn out fabrics
					 float FabricMask = saturate(0.6f-DiffuseDecayMask2x.a);

					 Diffuse.rgb = lerp(Diffuse.rgb,float3(0.9f,0.75f,0.6f),smoothstep(FabricMask,FabricMask+0.3f,(Weight*0.34f)*(1.0f-ClothMask)*0.7f));
					
					 Properties.b = lerp(Properties.b,0.0f,smoothstep(FabricMask,FabricMask+0.3f,(Weight*0.4f)*(1.0f-ClothMask)));
					 Properties.a = lerp(Properties.a,1.0f,smoothstep(FabricMask,FabricMask+0.3f,(Weight*0.4f)*(1.0f-ClothMask)));

					//Holes in fabrics
					 float WearMask = abs(0.8f-DiffuseDecayMask2x.a);
					 Diffuse.a = lerp(Diffuse.a,0.0f,step(WearMask,Weight*0.3f)*(1.0f-ClothMask));

					//Stains in fabric
					float StainMask = saturate(DiffuseDecayMask3x.r*5.0f);
					Diffuse.rgb = Multiply(Diffuse.rgb,float3(StainMask,StainMask,StainMask), clamp(Weight*2.0f,0.0f,1.0f));


					//Layers of dirt
					float DirtMask = clamp( NormalSample.b * NormalSample.b, 0, 1 );
					DirtMask = max(DirtMask,DiffuseDecayMask3x.g*1.5);
					float3 DirtDiffuse = float3(0.2f,0.1f,0.06f);
				
					
					DirtDiffuse *= Diffuse.rgb;
					Diffuse.rgb = lerp(Diffuse.rgb,DirtDiffuse,smoothstep(DirtMask*0.5f,DirtMask*1.5f,clamp(Weight*1.6f,0.0f,1.0f)));

					#endif
					//EK2

				#endif
				
				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input );


				//#if defined PARALLAX || defined REFRACT
				//	Out.Color = float4( Color, 1.0f );
				//#else
					Out.Color = float4( Color, Diffuse.a );
				//#endif

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

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input );

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

				Out.SSAOColor = PdxTex2D( SSAOColorMap, UV0 );
				Out.SSAOColor.rgb *= vPaletteColorHair.rgb;

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

				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input );

				Out.Color = float4( Color, Diffuse.a );
				
				Out.SSAOColor = PdxTex2D( SSAOColorMap, UV0 );
				Out.SSAOColor.rgb *= vPaletteColorHair.rgb;

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
				
				float3 Color = CommonPixelShader( Diffuse, Properties, NormalSample, Input );

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

				Out.SSAOColor = float4(0.0f,0.0f,0.0f,0.0f);
				return Out;
			}
		]]
	}
	#END-MOD

	# MOD(map-skybox)
	MainCode PS_Skybox
	{
		Input = "VS_OUTPUT_PDXMESHPORTRAIT"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				
				float3 WorldPos = Input.WorldSpacePos;
				WorldPos.y -= 100.0f;
				float Dist = distance(WorldPos.y,CameraPosition);
				float3 FromCameraDir = normalize(WorldPos * Dist * 0.05f - CameraPosition);
				//FromCameraDir.y -= 1000.0f;
				float4 Color = PdxTexCube(EnvironmentMap, FromCameraDir);
				//Color.rgb = CameraPosition*0.001f;
				return Color;

			}
		]]
	}

	# END MOD

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

Effect portrait_skinShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_teeth
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin"
	Defines = { "FAKE_SSS_EMISSIVE" }
}

Effect portrait_teeth
{
	VertexShader = "VS_portrait_blend_shapes"
	PixelShader = "PS_skin"
	Defines = { "FAKE_SSS_EMISSIVE" }
}

Effect portrait_skin_face
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin"
	Defines = { "FAKE_SSS_EMISSIVE" "ENABLE_TEXTURE_OVERRIDE" "PDX_MESH_BLENDSHAPES" }
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
	Defines = { "EMISSIVE_PROPERTIES_RED" "EYE_DECAL" }
}

Effect portrait_attachment
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = { "PDX_MESH_BLENDSHAPES" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" }
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
	Defines = {"PDX_MESH_BLENDSHAPES" "VARIATIONS_ENABLED" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" }
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
	Defines = { "VARIATIONS_ENABLED" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_pattern_alpha_to_coverageShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_variedShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_attachment_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "alpha_to_coverage"
	Defines = {  "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PDX_MESH_BLENDSHAPES"}
}

Effect portrait_attachment_alpha_to_coverageShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_hair
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	BlendState = "alpha_to_coverage"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "ALPHA_TO_COVERAGE" "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_transparency_hack
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	BlendState = "alpha_to_coverage"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "HAIR_TRANSPARENCY_HACK" "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hairShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" }
}

Effect portrait_hair_double_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair_double_sided"
	BlendState = "alpha_to_coverage"
	#DepthStencilState = "test_and_write"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_alpha
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	BlendState = "hair_alpha_blend"
	DepthStencilState = "hair_alpha_blend"
	Defines = { "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_opaque
{
	VertexShader = "VS_standard"
	PixelShader = "PS_hair"
	
	Defines = { "WRITE_ALPHA_ONE" "PDX_MESH_BLENDSHAPES" "HAIR_AGING_DECAL"}
}

Effect portrait_hair_opaqueShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	RasterizerState = "ShadowRasterizerState"
	Defines = { "PDXMESH_DISABLE_DITHERED_OPACITY" }
}

Effect portrait_attachment_alpha
{
	VertexShader = "VS_standard"
	PixelShader = "PS_attachment"
	BlendState = "hair_alpha_blend"
	DepthStencilState = "hair_alpha_blend"
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
	Defines = { "HAIR_AGING_DECAL"}
}

#EK2
Effect skin_alpha
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin_alpha"
	Defines = { "PDX_MESH_BLENDSHAPES" }
}

Effect portrait_skin_hair_color
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin"
	Defines = {"PDX_MESH_BLENDSHAPES" "FAKE_SSS_EMISSIVE" "SKIN_TO_HAIR_COLOR"}
}

Effect portrait_eye_no_decal
{
	VertexShader = "VS_standard"
	PixelShader = "PS_eye"
	Defines = {"PDX_MESH_BLENDSHAPES" "EMISSIVE_PROPERTIES_RED" }
}

Effect portrait_eye_shift
{
	VertexShader = "VS_standard"
	PixelShader = "PS_eye"
	Defines = {"PDX_MESH_BLENDSHAPES" "EMISSIVE_PROPERTIES_RED" "EYE_DECAL" "HSV_SHIFT"}
}

Effect portrait_eye_blind
{
	VertexShader = "VS_standard"
	PixelShader = "PS_eye"
	Defines = {"PDX_MESH_BLENDSHAPES" "EYE_DECAL" "EYE_BLIND"}
}

Effect portrait_attachment_glass
{
    VertexShader = "VS_standard"
    PixelShader = "PS_attachment"
    BlendState = "alpha_to_coverage"
    #DepthStencilState = "hair_alpha_blend"
    Defines = { "PDX_MESH_BLENDSHAPES" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PARALLAX" "REFRACT"}
}

Effect portrait_attachment_pattern_glass
{
    VertexShader = "VS_standard"
    PixelShader = "PS_attachment"
    BlendState = "alpha_to_coverage"
    #DepthStencilState = "hair_alpha_blend"
    Defines = {"PDX_MESH_BLENDSHAPES" "VARIATIONS_ENABLED" "EMISSIVE_NORMAL_BLUE" "ATTACHEMENT_DECAY" "PARALLAX" "REFRACT"}
}

Effect skybox_attachment
{
	VertexShader = "VS_standard"
	PixelShader = "PS_Skybox"
	Defines = { "SKYBOX" }
}
#END-EK2

#MOD-HAIR-BLEND
Effect portrait_color_blend
{
	VertexShader = "VS_standard"
	PixelShader = "PS_skin_hair_eye_blend"
	BlendState = "alpha_to_coverage"
	RasterizerState = "rasterizer_no_culling"
	Defines = { "ALPHA_TO_COVERAGE" "PDX_MESH_BLENDSHAPES" "EMISSIVE_PROPERTIES_RED"}
}
#END-MOD
