import 'package:flutter/material.dart';

enum TrailRenderType {
  basic,
  smoke,
  fire,
  water,
  laser,
  plasma,
  glitch,
  ink,
  magma,
  ice,
  galaxy,
  galaxyReveal,
  speedForce,
  electric,
  comic,
  punkRiff,
  graffiti,
  urbanGraffiti,
  halftoneExplosion,
  stickerBomb,
  glitchPrint,
  web,
  webLegendary,
  comicSpiderverse,
  comicSpiderverseV2,
  comicSpiderverseRebuilt,
  inkBrush,
  electricArc,
  goldenThread,
  goldenAura,
  holidaySpark,
  upside,
  binaryRain,
}

class TrailParticleConfig {
  const TrailParticleConfig({
    this.enabled = false,
    this.count = 0,
    this.minRadius = 1.5,
    this.maxRadius = 5,
    this.lifetimeSeconds = 0.8,
    this.spread = 10,
    this.jitter = 0.5,
    this.speed = 1,
  });

  final bool enabled;
  final int count;
  final double minRadius;
  final double maxRadius;
  final double lifetimeSeconds;
  final double spread;
  final double jitter;
  final double speed;
}

class TrailSkinConfig {
  const TrailSkinConfig({
    required this.id,
    required this.name,
    required this.renderType,
    required this.primaryColor,
    required this.secondaryColor,
    this.thickness = 1.0,
    this.opacity = 1.0,
    this.glow = false,
    this.headAssetPath,
    this.effectIntensity = 1.0,
    this.particle = const TrailParticleConfig(),
    this.visualStepFps = 12,
    this.snapshotCount = 5,
    this.chromaOffsetPx = 1.8,
    this.web = const WebTrailConfig(),
    this.webLegendary = const WebTrailLegendaryConfig(),
    this.comicSpiderverse = const ComicSpiderverseTrailConfig(),
    this.comicSpiderverseV2 = const ComicSpiderverseTrailV2Config(),
    this.comicSpiderverseRebuilt = const ComicSpiderverseRebuiltTrailConfig(),
    this.ink = const InkBrushTrailConfig(),
    this.arc = const ElectricArcTrailConfig(),
    this.golden = const GoldenThreadTrailConfig(),
    this.aura = const GoldenAuraTrailConfig(),
    this.smoke = const SmokeTrailConfig(),
    this.plasma = const PlasmaTrailConfig(),
    this.glitch = const GlitchTrailConfig(),
    this.inkLiquid = const InkTrailConfig(),
    this.magma = const MagmaTrailConfig(),
    this.ice = const IceTrailConfig(),
    this.galaxy = const GalaxyTrailConfig(),
    this.galaxyReveal = const GalaxyRevealConfig(),
    this.speedForce = const SpeedForceTrailConfig(),
    this.holidaySpark = const HolidaySparkTrailConfig(),
    this.upside = const UpsideTrailConfig(),
    this.binaryRain = const BinaryRainTrailConfig(),
    this.punkRiff = const PunkRiffTrailConfig(),
    this.graffiti = const GraffitiTrailConfig(),
    this.urbanGraffiti = const UrbanGraffitiTrailConfig(),
    this.halftoneExplosion = const HalftoneExplosionTrailConfig(),
    this.stickerBomb = const StickerBombTrailConfig(),
    this.glitchPrint = const GlitchPrintTrailConfig(),
  });

  final String id;
  final String name;
  final TrailRenderType renderType;
  final Color primaryColor;
  final Color secondaryColor;
  final double thickness;
  final double opacity;
  final bool glow;
  final String? headAssetPath;
  final double effectIntensity;
  final TrailParticleConfig particle;
  final int visualStepFps;
  final int snapshotCount;
  final double chromaOffsetPx;
  final WebTrailConfig web;
  final WebTrailLegendaryConfig webLegendary;
  final ComicSpiderverseTrailConfig comicSpiderverse;
  final ComicSpiderverseTrailV2Config comicSpiderverseV2;
  final ComicSpiderverseRebuiltTrailConfig comicSpiderverseRebuilt;
  final InkBrushTrailConfig ink;
  final ElectricArcTrailConfig arc;
  final GoldenThreadTrailConfig golden;
  final GoldenAuraTrailConfig aura;
  final SmokeTrailConfig smoke;
  final PlasmaTrailConfig plasma;
  final GlitchTrailConfig glitch;
  final InkTrailConfig inkLiquid;
  final MagmaTrailConfig magma;
  final IceTrailConfig ice;
  final GalaxyTrailConfig galaxy;
  final GalaxyRevealConfig galaxyReveal;
  final SpeedForceTrailConfig speedForce;
  final HolidaySparkTrailConfig holidaySpark;
  final UpsideTrailConfig upside;
  final BinaryRainTrailConfig binaryRain;
  final PunkRiffTrailConfig punkRiff;
  final GraffitiTrailConfig graffiti;
  final UrbanGraffitiTrailConfig urbanGraffiti;
  final HalftoneExplosionTrailConfig halftoneExplosion;
  final StickerBombTrailConfig stickerBomb;
  final GlitchPrintTrailConfig glitchPrint;
}

class PunkRiffTrailConfig {
  const PunkRiffTrailConfig({
    this.coreWidth = 0.86,
    this.pinkMassOpacity = 0.78,
    this.yellowBoltFrequency = 0.36,
    this.paperFragmentFrequency = 0.3,
    this.inkSplashFrequency = 0.24,
    this.iconStampFrequency = 0.26,
    this.iconStampSpacing = 0.62,
    this.iconStampLifetime = 0.95,
    this.iconStampScaleMin = 0.2,
    this.iconStampScaleMax = 0.34,
    this.iconStampOpacity = 0.9,
    this.iconStampRotationJitter = 0.24,
    this.glitchStrength = 0.18,
    this.glitchOffset = 0.08,
    this.halftoneOpacity = 0.2,
    this.pulseStrength = 0.12,
    this.pulseSpeed = 1.8,
    this.visualFps = 12,
  });

  final double coreWidth;
  final double pinkMassOpacity;
  final double yellowBoltFrequency;
  final double paperFragmentFrequency;
  final double inkSplashFrequency;
  final double iconStampFrequency;
  final double iconStampSpacing;
  final double iconStampLifetime;
  final double iconStampScaleMin;
  final double iconStampScaleMax;
  final double iconStampOpacity;
  final double iconStampRotationJitter;
  final double glitchStrength;
  final double glitchOffset;
  final double halftoneOpacity;
  final double pulseStrength;
  final double pulseSpeed;
  final int visualFps;
}

class GraffitiTrailConfig {
  const GraffitiTrailConfig({
    this.coreWidth = 0.9,
    this.sprayParticleFrequency = 0.34,
    this.sprayParticleLifetime = 0.62,
    this.splashFrequency = 0.24,
    this.dripFrequency = 0.16,
    this.colorPalette = const <Color>[
      Color(0xFFFF2EC9), // magenta
      Color(0xFF22D3EE), // cyan
      Color(0xFFFFE84A), // yellow
      Color(0xFFA3FF12), // acid green
      Color(0xFFF8FAFC), // white
    ],
  });

  final double coreWidth;
  final double sprayParticleFrequency;
  final double sprayParticleLifetime;
  final double splashFrequency;
  final double dripFrequency;
  final List<Color> colorPalette;
}

class UrbanGraffitiTrailConfig {
  const UrbanGraffitiTrailConfig({
    this.mainWidth = 1.0,
    this.lineJitter = 0.03,
    this.widthVariance = 0.1,
    this.alphaVariance = 0.09,
    this.spraySpacingMinPx = 18,
    this.spraySpacingMaxPx = 28,
    this.sprayScaleMin = 1.4,
    this.sprayScaleMax = 1.8,
    this.sprayOpacityMin = 0.12,
    this.sprayOpacityMax = 0.25,
    this.splashMilestoneSpacingMinPx = 70,
    this.splashMilestoneSpacingMaxPx = 120,
    this.splashChanceOnTurn = 0.25,
    this.splashChanceOnNode = 0.65,
    this.splashScaleMin = 0.4,
    this.splashScaleMax = 0.8,
    this.splashOpacityMin = 0.45,
    this.splashOpacityMax = 0.8,
    this.dripChance = 0.03,
    this.dripScaleMin = 0.5,
    this.dripScaleMax = 0.9,
    this.dripOpacityMin = 0.5,
    this.dripOpacityMax = 0.7,
    this.tagChance = 0.01,
    this.tagScaleMin = 0.3,
    this.tagScaleMax = 0.6,
    this.tagOpacityMin = 0.35,
    this.tagOpacityMax = 0.65,
    this.maxSplashes = 3,
    this.maxDrips = 2,
    this.maxTags = 1,
    this.nodeAvoidRadiusCells = 0.32,
    this.debugMode = false,
  });

  final double mainWidth;
  final double lineJitter;
  final double widthVariance;
  final double alphaVariance;
  final double spraySpacingMinPx;
  final double spraySpacingMaxPx;
  final double sprayScaleMin;
  final double sprayScaleMax;
  final double sprayOpacityMin;
  final double sprayOpacityMax;
  final double splashMilestoneSpacingMinPx;
  final double splashMilestoneSpacingMaxPx;
  final double splashChanceOnTurn;
  final double splashChanceOnNode;
  final double splashScaleMin;
  final double splashScaleMax;
  final double splashOpacityMin;
  final double splashOpacityMax;
  final double dripChance;
  final double dripScaleMin;
  final double dripScaleMax;
  final double dripOpacityMin;
  final double dripOpacityMax;
  final double tagChance;
  final double tagScaleMin;
  final double tagScaleMax;
  final double tagOpacityMin;
  final double tagOpacityMax;
  final int maxSplashes;
  final int maxDrips;
  final int maxTags;
  final double nodeAvoidRadiusCells;
  final bool debugMode;
}

class HalftoneExplosionTrailConfig {
  const HalftoneExplosionTrailConfig({
    this.coreWidth = 0.88,
    this.halftoneSize = 0.04,
    this.burstFrequency = 0.24,
    this.burstLifetime = 0.58,
    this.impactFlashFrequency = 0.2,
  });

  final double coreWidth;
  final double halftoneSize;
  final double burstFrequency;
  final double burstLifetime;
  final double impactFlashFrequency;
}

class StickerBombTrailConfig {
  const StickerBombTrailConfig({
    this.coreWidth = 0.86,
    this.stickerFrequency = 0.28,
    this.stickerLifetime = 0.72,
    this.rotationVariance = 0.4,
    this.scaleVariance = 0.26,
  });

  final double coreWidth;
  final double stickerFrequency;
  final double stickerLifetime;
  final double rotationVariance;
  final double scaleVariance;
}

class GlitchPrintTrailConfig {
  const GlitchPrintTrailConfig({
    this.coreWidth = 0.82,
    this.glitchOffset = 0.08,
    this.rgbShift = 0.06,
    this.fragmentFrequency = 0.34,
    this.fragmentSize = 0.08,
    this.noiseIntensity = 0.22,
  });

  final double coreWidth;
  final double glitchOffset;
  final double rgbShift;
  final double fragmentFrequency;
  final double fragmentSize;
  final double noiseIntensity;
}

class WebTrailConfig {
  const WebTrailConfig({
    this.mainStrandWidth = 0.2,
    this.strandGap = 0.16,
    this.bridgeSpacing = 0.32,
    this.bridgeJitter = 0.11,
    this.bridgeOpacity = 0.48,
    this.strandOpacity = 0.9,
    this.highlightStrength = 0.34,
    this.mainThicknessVariance = 0.18,
    this.mainTaperStrength = 0.22,
    this.glowOpacity = 0.2,
    this.fiberNoise = 0.14,
    this.fiberAlpha = 0.22,
    this.microBridgeDensity = 0.62,
    this.maxMicroBridgesPerSegment = 3,
    this.nodeBurstLines = 7,
    this.nodeBurstArcHints = 2,
    this.nodeBurstScale = 0.36,
    this.nodeBurstOpacity = 0.34,
    this.tensionAmplitude = 0.055,
    this.tensionSpeed = 0.72,
    this.elasticity = 0.18,
    this.depthOffset = 0.028,
    this.shimmerSpeed = 0.26,
    this.sparkleFrequency = 0.18,
    this.silkTravelerCount = 8,
    this.dustParticleCount = 16,
    this.silkFragmentFrequency = 0.08,
  });

  final double mainStrandWidth;
  final double strandGap;
  final double bridgeSpacing;
  final double bridgeJitter;
  final double bridgeOpacity;
  final double strandOpacity;
  final double highlightStrength;
  final double mainThicknessVariance;
  final double mainTaperStrength;
  final double glowOpacity;
  final double fiberNoise;
  final double fiberAlpha;
  final double microBridgeDensity;
  final int maxMicroBridgesPerSegment;
  final int nodeBurstLines;
  final int nodeBurstArcHints;
  final double nodeBurstScale;
  final double nodeBurstOpacity;
  final double tensionAmplitude;
  final double tensionSpeed;
  final double elasticity;
  final double depthOffset;
  final double shimmerSpeed;
  final double sparkleFrequency;
  final int silkTravelerCount;
  final int dustParticleCount;
  final double silkFragmentFrequency;
}

class WebTrailLegendaryConfig {
  const WebTrailLegendaryConfig({
    this.mainWidth = 0.25,
    this.glowIntensity = 0.36,
    this.chromaticOffsetStrength = 0.055,
    this.bridgeDensity = 0.5,
    this.sparkleRate = 0.24,
    this.energyFlickRate = 0.16,
    this.nodeBurstScale = 0.44,
    this.highlightSpeed = 0.34,
    this.halftoneFrequency = 0.14,
    this.glitchFlashProbability = 0.12,
    this.sparkleCount = 14,
    this.energyFlickCount = 8,
    this.maxBridgesPerSegment = 3,
  });

  final double mainWidth;
  final double glowIntensity;
  final double chromaticOffsetStrength;
  final double bridgeDensity;
  final double sparkleRate;
  final double energyFlickRate;
  final double nodeBurstScale;
  final double highlightSpeed;
  final double halftoneFrequency;
  final double glitchFlashProbability;
  final int sparkleCount;
  final int energyFlickCount;
  final int maxBridgesPerSegment;
}

class ComicSpiderverseTrailConfig {
  const ComicSpiderverseTrailConfig({
    this.baseOpacityMin = 0.7,
    this.baseOpacityMax = 1.0,
    this.scaleMin = 0.9,
    this.scaleMax = 1.1,
    this.rotationJitterDeg = 3.0,
    this.chromaticOffsetPx = 2.0,
    this.chromaticOpacity = 0.38,
    this.particleLifeMinMs = 300,
    this.particleLifeMaxMs = 600,
    this.comicDropDistanceMin = 120,
    this.comicDropDistanceMax = 180,
    this.comicDropLifeMinMs = 700,
    this.comicDropLifeMaxMs = 1200,
    this.glitchSliceMinMs = 500,
    this.glitchSliceMaxMs = 1000,
    this.glitchSliceLifeMinMs = 80,
    this.glitchSliceLifeMaxMs = 120,
    this.textSpawnChance = 0.2,
    this.maxParticles = 40,
    this.maxComicDrops = 2,
    this.maxBursts = 3,
  });

  final double baseOpacityMin;
  final double baseOpacityMax;
  final double scaleMin;
  final double scaleMax;
  final double rotationJitterDeg;
  final double chromaticOffsetPx;
  final double chromaticOpacity;
  final int particleLifeMinMs;
  final int particleLifeMaxMs;
  final int comicDropDistanceMin;
  final int comicDropDistanceMax;
  final int comicDropLifeMinMs;
  final int comicDropLifeMaxMs;
  final int glitchSliceMinMs;
  final int glitchSliceMaxMs;
  final int glitchSliceLifeMinMs;
  final int glitchSliceLifeMaxMs;
  final double textSpawnChance;
  final int maxParticles;
  final int maxComicDrops;
  final int maxBursts;
}

class ComicSpiderverseTrailV2Config {
  const ComicSpiderverseTrailV2Config({
    this.mainTrailWidth = 1.08,
    this.baseTrailOpacity = 0.96,
    this.cyanOffsetX = -4,
    this.cyanOffsetY = -1,
    this.magentaOffsetX = 4,
    this.magentaOffsetY = 1,
    this.chromaticOpacity = 0.72,
    this.glitchFrequency = 0.52,
    this.glitchDurationMin = 60,
    this.glitchDurationMax = 120,
    this.halftoneOpacityMin = 0.18,
    this.halftoneOpacityMax = 0.35,
    this.inkOpacityMin = 0.22,
    this.inkOpacityMax = 0.38,
    this.nodeBurstScaleMin = 0.5,
    this.nodeBurstScaleMax = 1.2,
    this.comicElementSpawnDistanceMin = 80,
    this.comicElementSpawnDistanceMax = 140,
    this.comicElementMaxActive = 3,
    this.particleMaxActive = 56,
    this.steppedFrameMs = 41,
    this.steppedFrameJitter = 4,
    this.nodeTextSpawnChance = 0.45,
    this.enableDebugBoost = false,
  });

  final double mainTrailWidth;
  final double baseTrailOpacity;
  final double cyanOffsetX;
  final double cyanOffsetY;
  final double magentaOffsetX;
  final double magentaOffsetY;
  final double chromaticOpacity;
  final double glitchFrequency;
  final int glitchDurationMin;
  final int glitchDurationMax;
  final double halftoneOpacityMin;
  final double halftoneOpacityMax;
  final double inkOpacityMin;
  final double inkOpacityMax;
  final double nodeBurstScaleMin;
  final double nodeBurstScaleMax;
  final int comicElementSpawnDistanceMin;
  final int comicElementSpawnDistanceMax;
  final int comicElementMaxActive;
  final int particleMaxActive;
  final int steppedFrameMs;
  final int steppedFrameJitter;
  final double nodeTextSpawnChance;
  final bool enableDebugBoost;
}

class ComicSpiderverseRebuiltTrailConfig {
  const ComicSpiderverseRebuiltTrailConfig({
    this.mainSpriteOpacity = 0.95,
    this.supportLineOpacity = 0.85,
    this.supportLineMinPx = 10.0,
    this.supportLineMaxPx = 17.0,
    this.offsetShadowOpacity = 0.44,
    this.offsetShadowScale = 1.35,
    this.chromaticOpacity = 0.65,
    this.chromaticOffsetX = 3.0,
    this.chromaticOffsetY = 1.0,
    this.nodeHitChromaticBoost = 1.32,
    this.halftoneOpacity = 0.14,
    this.inkOpacity = 0.22,
    this.burstOpacity = 0.95,
    this.bubbleOpacity = 0.9,
    this.textOpacity = 1.0,
    this.frameSliceOpacity = 0.62,
    this.particleMaxActive = 48,
    this.burstMaxActive = 2,
    this.bubbleMaxActive = 1,
    this.textMaxActive = 1,
    this.inkMaxActive = 2,
    this.halftoneMaxActive = 2,
    this.decalMaxActive = 1,
    this.frameSliceMaxActive = 1,
    this.streakSpacingMinPx = 20.0,
    this.streakSpacingMaxPx = 30.0,
    this.longSegmentSpawnMinPx = 160.0,
    this.longSegmentSpawnMaxPx = 240.0,
    this.lingerDecalCount = 2,
    this.lingerHoldFrames = 10,
    this.steppedFrameMs = 41,
    this.steppedFrameJitter = 3,
    this.nodeTextSpawnChance = 0.26,
    this.turnTextSpawnChance = 0.12,
    this.swayAmount = 0.2,
    this.swaySpeed = 0.9,
    this.debugMode = false,
    this.debugVisualDensity = false,
  });

  final double mainSpriteOpacity;
  final double supportLineOpacity;
  final double supportLineMinPx;
  final double supportLineMaxPx;
  final double offsetShadowOpacity;
  final double offsetShadowScale;
  final double chromaticOpacity;
  final double chromaticOffsetX;
  final double chromaticOffsetY;
  final double nodeHitChromaticBoost;
  final double halftoneOpacity;
  final double inkOpacity;
  final double burstOpacity;
  final double bubbleOpacity;
  final double textOpacity;
  final double frameSliceOpacity;
  final int particleMaxActive;
  final int burstMaxActive;
  final int bubbleMaxActive;
  final int textMaxActive;
  final int inkMaxActive;
  final int halftoneMaxActive;
  final int decalMaxActive;
  final int frameSliceMaxActive;
  final double streakSpacingMinPx;
  final double streakSpacingMaxPx;
  final double longSegmentSpawnMinPx;
  final double longSegmentSpawnMaxPx;
  final int lingerDecalCount;
  final int lingerHoldFrames;
  final int steppedFrameMs;
  final int steppedFrameJitter;
  final double nodeTextSpawnChance;
  final double turnTextSpawnChance;
  final double swayAmount;
  final double swaySpeed;
  final bool debugMode;
  final bool debugVisualDensity;
}

class InkBrushTrailConfig {
  const InkBrushTrailConfig({
    this.baseWidth = 0.95,
    this.widthVariance = 0.28,
    this.edgeRoughness = 0.08,
    this.splatterRate = 0.18,
  });

  final double baseWidth;
  final double widthVariance;
  final double edgeRoughness;
  final double splatterRate;
}

class ElectricArcTrailConfig {
  const ElectricArcTrailConfig({
    this.mainWidth = 0.78,
    this.glowStrength = 0.62,
    this.branchFrequency = 0.34,
    this.branchLength = 0.2,
    this.sparkFrequency = 0.28,
  });

  final double mainWidth;
  final double glowStrength;
  final double branchFrequency;
  final double branchLength;
  final double sparkFrequency;
}

class GoldenThreadTrailConfig {
  const GoldenThreadTrailConfig({
    this.threadWidth = 0.76,
    this.highlightStrength = 0.42,
    this.glowOpacity = 0.24,
    this.sparkleFrequency = 0.16,
  });

  final double threadWidth;
  final double highlightStrength;
  final double glowOpacity;
  final double sparkleFrequency;
}

class GoldenAuraTrailConfig {
  const GoldenAuraTrailConfig({
    this.coreWidth = 0.72,
    this.auraWidth = 1.2,
    this.glowWidth = 1.95,
    this.pulseStrength = 0.18,
    this.pulseSpeed = 1.9,
    this.edgeNoiseAmount = 0.11,
    this.edgeNoiseSpeed = 1.6,
    this.sparkFrequency = 0.28,
    this.sparkLifetime = 0.7,
    this.sparkRiseSpeed = 0.8,
    this.coreColor = const Color(0xFFFFF8CC),
    this.auraColor = const Color(0xFFFFD84F),
    this.glowColor = const Color(0xFFFFB300),
  });

  final double coreWidth;
  final double auraWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double edgeNoiseAmount;
  final double edgeNoiseSpeed;
  final double sparkFrequency;
  final double sparkLifetime;
  final double sparkRiseSpeed;
  final Color coreColor;
  final Color auraColor;
  final Color glowColor;
}

class SmokeTrailConfig {
  const SmokeTrailConfig({
    this.spawnRate = 16.0,
    this.minSize = 0.22,
    this.maxSize = 0.46,
    this.minLifetime = 0.6,
    this.maxLifetime = 1.5,
    this.upwardDrift = 0.22,
    this.sidewaysJitter = 0.16,
    this.opacityStart = 0.58,
    this.opacityEnd = 0.0,
    this.emissionOffsetBehindHead = 0.24,
  });

  final double spawnRate;
  final double minSize;
  final double maxSize;
  final double minLifetime;
  final double maxLifetime;
  final double upwardDrift;
  final double sidewaysJitter;
  final double opacityStart;
  final double opacityEnd;
  final double emissionOffsetBehindHead;
}

class PlasmaTrailConfig {
  const PlasmaTrailConfig({
    this.coreWidth = 0.62,
    this.plasmaWidth = 1.02,
    this.glowWidth = 1.6,
    this.pulseStrength = 0.12,
    this.pulseSpeed = 1.6,
    this.innerFlowSpeed = 1.8,
    this.sparkFrequency = 0.26,
    this.sparkLifetime = 0.55,
    this.coreColor = const Color(0xFFEAF7FF),
    this.plasmaColor = const Color(0xFF64D9FF),
    this.glowColor = const Color(0xFF775BFF),
  });

  final double coreWidth;
  final double plasmaWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double innerFlowSpeed;
  final double sparkFrequency;
  final double sparkLifetime;
  final Color coreColor;
  final Color plasmaColor;
  final Color glowColor;
}

class GlitchTrailConfig {
  const GlitchTrailConfig({
    this.coreWidth = 0.76,
    this.chromaticOffset = 0.08,
    this.glitchFrequency = 0.32,
    this.fragmentSize = 0.12,
    this.fragmentLifetime = 0.42,
    this.flickerStrength = 0.18,
    this.stepVisualFps = 14,
    this.coreColor = const Color(0xFFE2E8F0),
    this.offsetColorA = const Color(0xFF22D3EE),
    this.offsetColorB = const Color(0xFFF472B6),
  });

  final double coreWidth;
  final double chromaticOffset;
  final double glitchFrequency;
  final double fragmentSize;
  final double fragmentLifetime;
  final double flickerStrength;
  final int stepVisualFps;
  final Color coreColor;
  final Color offsetColorA;
  final Color offsetColorB;
}

class InkTrailConfig {
  const InkTrailConfig({
    this.baseWidth = 0.92,
    this.widthVariation = 0.22,
    this.edgeNoiseAmount = 0.05,
    this.dropletFrequency = 0.2,
    this.dropletSize = 0.05,
    this.glossStrength = 0.22,
    this.coreColor = const Color(0xFF0F172A),
    this.highlightColor = const Color(0xFF334155),
  });

  final double baseWidth;
  final double widthVariation;
  final double edgeNoiseAmount;
  final double dropletFrequency;
  final double dropletSize;
  final double glossStrength;
  final Color coreColor;
  final Color highlightColor;
}

class MagmaTrailConfig {
  const MagmaTrailConfig({
    this.coreWidth = 0.5,
    this.magmaWidth = 0.92,
    this.crustWidth = 1.28,
    this.heatPulseStrength = 0.14,
    this.heatPulseSpeed = 1.45,
    this.emberFrequency = 0.28,
    this.emberLifetime = 0.62,
    this.coreColor = const Color(0xFFFFF08A),
    this.magmaColor = const Color(0xFFFF5B1F),
    this.crustColor = const Color(0xFF3A0F08),
    this.glowColor = const Color(0xFFFF8B3D),
  });

  final double coreWidth;
  final double magmaWidth;
  final double crustWidth;
  final double heatPulseStrength;
  final double heatPulseSpeed;
  final double emberFrequency;
  final double emberLifetime;
  final Color coreColor;
  final Color magmaColor;
  final Color crustColor;
  final Color glowColor;
}

class IceTrailConfig {
  const IceTrailConfig({
    this.coreWidth = 0.62,
    this.frostWidth = 1.02,
    this.glowStrength = 0.24,
    this.sparkleFrequency = 0.2,
    this.sparkleLifetime = 0.52,
    this.crystalDetailAmount = 0.12,
    this.coreColor = const Color(0xFFF1F8FF),
    this.frostColor = const Color(0xFFBFE9FF),
    this.glowColor = const Color(0xFF7DD3FC),
  });

  final double coreWidth;
  final double frostWidth;
  final double glowStrength;
  final double sparkleFrequency;
  final double sparkleLifetime;
  final double crystalDetailAmount;
  final Color coreColor;
  final Color frostColor;
  final Color glowColor;
}

class GalaxyTrailConfig {
  const GalaxyTrailConfig({
    this.coreWidth = 0.66,
    this.nebulaWidth = 1.25,
    this.glowWidth = 1.9,
    this.pulseStrength = 0.1,
    this.pulseSpeed = 1.1,
    this.innerDriftSpeed = 1.4,
    this.starDustFrequency = 0.26,
    this.starDustLifetime = 0.7,
    this.sparkleFrequency = 0.16,
    this.sparkleLifetime = 0.44,
    this.coreColor = const Color(0xFF15122B),
    this.nebulaColorA = const Color(0xFF7C3AED),
    this.nebulaColorB = const Color(0xFF22D3EE),
    this.glowColor = const Color(0xFFC084FC),
  });

  final double coreWidth;
  final double nebulaWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double innerDriftSpeed;
  final double starDustFrequency;
  final double starDustLifetime;
  final double sparkleFrequency;
  final double sparkleLifetime;
  final Color coreColor;
  final Color nebulaColorA;
  final Color nebulaColorB;
  final Color glowColor;
}

class GalaxyRevealConfig {
  const GalaxyRevealConfig({
    this.radius = 0.44,
    this.softness = 0.62,
    this.enableGlow = true,
    this.enableSparkles = true,
    this.enableBloom = true,
    this.textureAsset = 'assets/galaxy_trail/galaxy_trail.webp',
  });

  final double radius;
  final double softness;
  final bool enableGlow;
  final bool enableSparkles;
  final bool enableBloom;
  final String textureAsset;
}

class SpeedForceTrailConfig {
  const SpeedForceTrailConfig({
    this.coreWidth = 0.72,
    this.glowWidth = 1.42,
    this.pulseStrength = 0.17,
    this.pulseSpeed = 2.2,
    this.streakFrequency = 0.34,
    this.streakLength = 0.2,
    this.streakOpacity = 0.34,
    this.sparkFrequency = 0.24,
    this.sparkLifetime = 0.42,
    this.echoTrailCount = 2,
    this.echoTrailOpacity = 0.16,
    this.turnBurstStrength = 0.3,
    this.coreColor = const Color(0xFFFFF7CC),
    this.glowColor = const Color(0xFFFFC53A),
    this.streakColor = const Color(0xFFFF8A00),
    this.sparkColor = const Color(0xFFFFE066),
  });

  final double coreWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double streakFrequency;
  final double streakLength;
  final double streakOpacity;
  final double sparkFrequency;
  final double sparkLifetime;
  final int echoTrailCount;
  final double echoTrailOpacity;
  final double turnBurstStrength;
  final Color coreColor;
  final Color glowColor;
  final Color streakColor;
  final Color sparkColor;
}

class HolidaySparkTrailConfig {
  const HolidaySparkTrailConfig({
    this.coreWidth = 0.74,
    this.glowWidth = 1.52,
    this.sparkleFrequency = 0.22,
    this.sparkleLifetime = 0.58,
    this.ornamentDotFrequency = 0.14,
    this.pulseStrength = 0.12,
    this.pulseSpeed = 1.65,
    this.coreColor = const Color(0xFFC1121F),
    this.glowColor = const Color(0xFFFFE6A0),
    this.sparkleColors = const <Color>[
      Color(0xFFFFF4D2),
      Color(0xFFFFD166),
      Color(0xFFDA1E37),
      Color(0xFF2E7D32),
    ],
  });

  final double coreWidth;
  final double glowWidth;
  final double sparkleFrequency;
  final double sparkleLifetime;
  final double ornamentDotFrequency;
  final double pulseStrength;
  final double pulseSpeed;
  final Color coreColor;
  final Color glowColor;
  final List<Color> sparkleColors;
}

class UpsideTrailConfig {
  const UpsideTrailConfig({
    this.coreWidth = 0.72,
    this.auraWidth = 1.18,
    this.glowWidth = 1.84,
    this.pulseStrength = 0.14,
    this.pulseSpeed = 1.42,
    this.redBoltFrequency = 0.28,
    this.redBoltLength = 0.2,
    this.sporeFrequency = 0.22,
    this.sporeLifetime = 0.9,
    this.coreColor = const Color(0xFF16070A),
    this.auraColor = const Color(0xFF4A0C16),
    this.glowColor = const Color(0xFF9D1121),
    this.boltColor = const Color(0xFFFF3B4D),
  });

  final double coreWidth;
  final double auraWidth;
  final double glowWidth;
  final double pulseStrength;
  final double pulseSpeed;
  final double redBoltFrequency;
  final double redBoltLength;
  final double sporeFrequency;
  final double sporeLifetime;
  final Color coreColor;
  final Color auraColor;
  final Color glowColor;
  final Color boltColor;
}

class BinaryRainTrailConfig {
  const BinaryRainTrailConfig({
    this.coreWidth = 0.74,
    this.glowWidth = 1.44,
    this.binaryDensity = 0.32,
    this.binarySpeed = 1.9,
    this.binaryOpacity = 0.72,
    this.digitalFragmentFrequency = 0.24,
    this.fragmentLifetime = 0.56,
    this.pulseStrength = 0.11,
    this.pulseSpeed = 1.7,
    this.coreColor = const Color(0xFF031B12),
    this.glowColor = const Color(0xFF22C55E),
    this.binaryColor = const Color(0xFF7DFFB3),
  });

  final double coreWidth;
  final double glowWidth;
  final double binaryDensity;
  final double binarySpeed;
  final double binaryOpacity;
  final double digitalFragmentFrequency;
  final double fragmentLifetime;
  final double pulseStrength;
  final double pulseSpeed;
  final Color coreColor;
  final Color glowColor;
  final Color binaryColor;
}
